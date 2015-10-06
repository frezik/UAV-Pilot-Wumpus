# Copyright (c) 2015  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package UAV::Pilot::Wumpus::Video;

use v5.14;
use warnings;
use Moose;
use namespace::autoclean;
use UAV::Pilot::Exceptions;
use UAV::Pilot::Video::H264Handler;
use IO::Socket::Multicast;
use Digest::Adler32::XS;

use constant BUF_READ_SIZE                 => 4096;
use constant WUMP_VIDEO_MAGIC_NUMBER       => 0xFB42;
use constant WUMP_VIDEO_MAGIC_NUMBER_ARRAY => [ 0xFB, 0x42 ];
use constant WUMP_HEADER_SIZE              => 32;
use constant WUMP_VERSION                  => 0x0001;

use constant {
    CODEC_TYPE_NULL  => 0,
    CODEC_TYPE_H264  => 1,
    CODEC_TYPE_MJPEG => 2,
};

use constant {
    _MODE_WUMP_HEADER   => 0,
    _MODE_FRAME         => 1,
    _MODE_NEXT_WUMP     => 2,
    _MODE_FRAME_DROP    => 3,
};

use constant {
    FLAG_RESERVED => 0,
    FLAG_KEYFRAME => 1,
    FLAG_FRAME_COUNT_OVERFLOWED => 2,
};


with 'UAV::Pilot::Logger';

has 'handlers' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[UAV::Pilot::Video::H264Handler]',
    default => sub {[]},
    handles => {
        'add_handler' => 'push',
    },
);
has 'condvar' => (
    is  => 'ro',
    isa => 'AnyEvent::CondVar',
);
has 'frames_processed' => (
    traits  => ['Number'],
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    handles => {
        '_add_frames_processed' => 'add',
    },
);
has '_io' => (
    is     => 'ro',
    isa    => 'Item',
    writer => '_set_io',
);
has '_byte_buffer' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[Int]',
    default => sub {[]},
    handles => {
        '_byte_buffer_splice' => 'splice',
        '_byte_buffer_size'   => 'count',
        '_byte_buffer_push'   => 'push',
    },
);
has '_mode' => (
    is  => 'rw',
    isa => 'Int',
    default => sub {
        my ($class) = @_;
        return $class->_MODE_WUMP_HEADER;
    },
);
has '_last_wump_header' => (
    is      => 'rw',
    isa     => 'HashRef[Item]',
    default => sub {{}},
);
has '_frame_count_seen' => (
    is => 'ro',
    isa => 'Int',
    default => 0,
    writer => '_set_frame_count_seen',
);
has '_digest' => (
    is => 'ro',
    isa => 'Item',
    default => sub { Digest::Adler32::XS->new },
);


sub BUILDARGS
{
    my ($class, $args) = @_;
    my $io = $class->_build_io( $args );

    $$args{'_io'} = $io;
    delete $$args{'multicast_ip'};
    delete $$args{'multicast_iface'};
    delete $$args{'port'};
    return $args;
}

sub init_event_loop
{
    my ($self) = @_;

    my $io_event; $io_event = AnyEvent->io(
        fh   => $self->_io,
        poll => 'r',
        cb   => sub {
            $self->_process_io;
            $io_event;
        },
    );

    return 1;
}


sub _read_wump_header
{
    my ($self) = @_;
    return 1 if $self->_byte_buffer_size < $self->WUMP_HEADER_SIZE;

    my @bytes = $self->_byte_buffer_splice( 0, $self->WUMP_HEADER_SIZE );

    my %packet;
    $packet{magic_number} = UAV::Pilot->convert_16bit_BE( @bytes[0,1] );
    $packet{version}      = UAV::Pilot->convert_16bit_BE( @bytes[2,3] );
    $packet{codec_id}     = UAV::Pilot->convert_16bit_BE( @bytes[4,5] );
    $packet{flags}        = UAV::Pilot->convert_32bit_BE( @bytes[6..9] );
    $packet{length}       = UAV::Pilot->convert_32bit_BE( @bytes[10..13] );
    $packet{width}        = UAV::Pilot->convert_16bit_BE( @bytes[14,15] );
    $packet{height}       = UAV::Pilot->convert_16bit_BE( @bytes[16,17] );
    $packet{checksum}     = UAV::Pilot->convert_32bit_BE( @bytes[18..21] );
    $packet{frame_count}  = UAV::Pilot->convert_32bit_BE( @bytes[22..25] );
    # 6 bytes reserved

    my $is_frame_count_overflowed = 0;

    if( $packet{magic_number} != $self->WUMP_VIDEO_MAGIC_NUMBER ) {
        $self->_logger->error( "Bad Wump header.  Got [$packet{magic_number}],"
            . " expected " . $self->WUMP_VIDEO_MAGIC_NUMBER );
        $self->_mode( $self->_MODE_NEXT_WUMP );
        return $self->_read_to_next_wump_header;
    }
    if( $packet{version} != $self->WUMP_VERSION ) {
        $self->_logger->error( "Got Wumpus Video version [$packet{version}]"
            . ", but only supports version [" . $self->WUMP_VERSION . "]"
        );
        $self->_mode( $self->_MODE_NEXT_WUMP );
        return $self->_read_to_next_wump_header;
    }
    if( $packet{codec_id} != $self->CODEC_TYPE_H264 ) {
        $self->_logger->error( "Can only handle encoding h264 packets" );
        $self->_mode( $self->_MODE_NEXT_WUMP );
        return $self->_read_to_next_wump_header;
    }
    if( $packet{flags} & (1 << $self->FLAG_FRAME_COUNT_OVERFLOWED) ) {
        $is_frame_count_overflowed = 1;
    }

    if( 
        (! $is_frame_count_overflowed)
        && ($packet{frame_count} <= $self->_frame_count_seen ) 
    ) {
        $self->_logger->info( "Received frame count $packet{frame_count}, but"
            . " we have seen count " . $self->_frame_count_seen
            . ", so dropping this frame" );
        $self->_mode( $self->_MODE_FRAME_DROP );
        return $self->_read_frame_drop;
    }

    $self->_logger->info( "Received frame " . $self->frames_processed
        . ", size $packet{length}, checksum "
        . sprintf( '%x', $packet{checksum} ) );

    $self->_add_frames_processed( 1 );
    $self->_last_wump_header( \%packet );
    $self->_mode( $self->_MODE_FRAME );
    return $self->_read_frame;
}

sub _read_to_next_wump_header
{
    my ($self) = @_;
    my @byte_buf = @{ $self->_byte_buffer };
    my @expect_signature = @{ $self->WUMP_VIDEO_MAGIC_NUMBER_ARRAY };

    foreach my $i (0 .. $#byte_buf) {
        if( ($expect_signature[0] == $byte_buf[$i])
            && ($expect_signature[1] == $byte_buf[$i + 1])
        ) {
            my @new_byte_buffer = @byte_buf[$i..$#byte_buf];
            $self->_byte_buffer( \@new_byte_buffer );
            $self->_mode( $self->_MODE_WUMP_HEADER );
            return $self->_read_wump_header;
        }
    }

    return 1;
}

sub _read_frame
{
    my ($self) = @_;
    my %header = %{ $self->_last_wump_header };
    my $frame_size = $header{length};
    if( $self->_byte_buffer_size < $frame_size ) {
        $self->_logger->info( "Need $frame_size bytes to read next frame"
            . ", but only " . $self->_byte_buffer_size . " available"
            . ", waiting for next read" );
        return 1;
    }

    my @frame = $self->_byte_buffer_splice( 0, $frame_size );

    my $digest = $self->_digest;
    $digest->add( @frame );
    my $expected_checksum = $header{checksum};
    my $got_checksum = $digest->digest;
    if( $got_checksum != $expected_checksum ) {
        $self->_logger->warn( "Got checksum " . sprintf( q{%08x}, $got_checksum )
            . ", expected checksum " . sprintf( q{%08x}, $expected_checksum )
            . ", dropping frame" );
    }
    else {
        $self->_logger->info( "Got expected checksum "
            . sprintf( q{%08x}, $expected_checksum ) );
    }

    foreach my $handler (@{ $self->handlers }) {
        eval { $handler->process_h264_frame(
                \@frame,
                # Redundant width/height in order to fill both width/height 
                # and encoded width/height params
                @header{qw{
                    width
                    height
                    width
                    height
                }}
        ) };
        if( $@ ) {
            $self->_logger->error( "Error processing frame: $@" );
        }
    }

    $self->_mode( $self->_MODE_WUMP_HEADER );
    return $self->_read_wump_header;
}

sub _read_frame_drop
{
    my ($self) = @_;
    my %header = %{ $self->_last_wump_header };
    my $frame_size = $header{length};
    if( $self->_byte_buffer_size < $frame_size ) {
        $self->_logger->info( "Need $frame_size bytes to read next frame"
            . ", but only " . $self->_byte_buffer_size . " available"
            . ", waiting for next read" );
        return 1;
    }

    $self->_mode( $self->_MODE_WUMP_HEADER );
    return $self->_read_wump_header;
}


sub _process_io
{
    my ($self) = @_;

    my $buf;
    my $read_count = $self->_io->read( $buf, $self->BUF_READ_SIZE );
    my @bytes = unpack 'C*', $buf;
    $self->_byte_buffer_push( @bytes );

    if( $self->_mode == $self->_MODE_WUMP_HEADER ) {
        $self->_read_wump_header;
    }
    elsif( $self->_mode == $self->_MODE_FRAME ) {
        $self->_read_frame;
    }
    elsif( $self->_mode == $self->_MODE_NEXT_WUMP ) {
        $self->_read_to_next_wump_header;
    }
    elsif( $self->_mode == $self->_MODE_FRAME_DROP ) {
        $self->_read_frame_drop;
    }

    return 1;
}

sub _build_io
{
    my ($class, $args) = @_;
    my $multicast_ip = $args->{multicast_ip};
    my $multicast_iface = $args->{multicast_iface};
    my $port = UAV::Pilot::Wumpus->DEFAULT_VIDEO_PORT;

    my $io = IO::Socket::Multicast->new(
        LocalPort => $port,
    ) or UAV::Pilot::IOException->throw(
        error => "Could not start multicast listener on port $port: $@",
    );
    $io->mcast_add( $multicast_ip, $multicast_iface );
    return $io;
}



no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

