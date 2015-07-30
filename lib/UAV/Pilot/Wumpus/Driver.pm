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
package UAV::Pilot::Wumpus::Driver;

use v5.14;
use Moose;
use namespace::autoclean;
use UAV::Pilot::Wumpus;
use UAV::Pilot::Wumpus::PacketFactory;
use Tie::IxHash;

use constant MAX_PACKET_QUEUE_LENGTH => 20;


has 'port' => (
    is      => 'ro',
    isa     => 'Int',
    default => UAV::Pilot::Wumpus::DEFAULT_PORT,
);
has 'host' => (
    is  => 'ro',
    isa => 'Str',
);
has '_socket' => (
    is  => 'rw',
    isa => 'IO::Socket::INET',
);
has '_ack_callback' => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub { sub {} },
    writer  => 'set_ack_callback',
);
has '_packet_queue' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        my %tie = ();
        tie %tie, 'Tie::IxHash';
        \%tie;
    },
);

with 'UAV::Pilot::Driver';
with 'UAV::Pilot::Logger';


sub connect
{
    my ($self) = @_;
    my $logger = $self->_logger;

    $logger->info( 'Connecting . . . ' );
    $self->_init_connection;

    my $startup_request = UAV::Pilot::Wumpus::PacketFactory->fresh_packet(
        'StartupRequest' );
    $logger->info( 'Sending StartupRequest packet' );
    $self->_send_packet( $startup_request );

    return 1;
}


sub send_radio_output_packet
{
    my ($self, @channels) = @_;
    my $radio_packet = UAV::Pilot::Wumpus::PacketFactory->fresh_packet(
        'RadioOutputs' );

    foreach my $i (1..8) {
        my $value = $channels[$i-1] // 0;
        my $packet_field = 'ch' . $i . '_out';
        $radio_packet->$packet_field( $value );
    }

    $self->_send_packet( $radio_packet );
    return 1;
}


sub _init_connection
{
    my ($self) = @_;
    my $logger = $self->_logger;

    $logger->info( 'Open UDP socket to ' . $self->host . ':' . $self->port );
    my $socket = IO::Socket::INET->new(
        Proto    => 'udp',
        PeerHost => $self->host,
        PeerPort => $self->port,
    ) or UAV::Pilot::IOException->throw({
        error => 'Could not open socket: ' . $!,
    });
    $logger->info( 'Done opening socket' );

    $self->_socket( $socket );
    return 1;
}

sub _send_packet
{
    my ($self, $packet) = @_;
    $packet->make_checksum_clean;
    $packet->write( $self->_socket );

    return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  UAV::Pilot::Wumpus::Driver

=head1 SYNOPSIS

    use UAV::Pilot::Wumpus::Driver;
    
    my $driver = UAV::Pilot::Wumpus::Driver->new({
        host => '10.0.0.10',
    });
    $driver->connect;

    $driver->send_radio_output_packet( 90, 100 );

=head1 DESCRIPTION

Driver for the WumpusRover.  Does the C<UAV::Pilot::Driver> role.

This is not intended to be used directly.  See 
C<UAV::Pilot::Wumpus::Control::Event> for the best way to control the 
WumpusRover from client code.

=cut
