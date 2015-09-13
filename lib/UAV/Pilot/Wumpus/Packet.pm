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
package UAV::Pilot::Wumpus::Packet;

use v5.14;
use Moose::Role;


use constant _USE_DEFAULT_BUILDARGS          => 1;
use constant _PACKET_QUEUE_MAP_KEY_SEPERATOR => '|';


has 'preamble' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0xBF24,
);
has 'version' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0x00,
);
has 'checksum' => (
    is     => 'ro',
    isa    => 'Int',
    writer => '_set_checksum',
);
has '_is_checksum_clean' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);
requires 'payload_length';
requires 'message_id';
requires 'payload_fields';
requires 'payload_fields_length';

with 'UAV::Pilot::Logger';


before 'BUILDARGS' => sub {
    my ($class, $args) = @_;
    return $args if delete $args->{fresh};
    return $args unless $class->_USE_DEFAULT_BUILDARGS;

    my $payload = delete $args->{payload};
    my @payload = @$payload;

    my %payload_fields_length = %{ $class->payload_fields_length };
    foreach my $field (@{ $class->payload_fields }) {
        $class->_logger->warn(
            "No entry for '$field' in $class->payload_fields_length"
        ) unless exists $payload_fields_length{$field};
        my $length = $payload_fields_length{$field} // 1;

        my $value = 0;
        $length = scalar(@payload)
            if $length == -1;
        if( $length > 0 ) {
            foreach (1 .. $length) {
                $value <<= 8;
                $value |= shift @payload;
            }
        }

        $args->{$field} = $value;
    }

    return $args;
};


sub write
{
    my ($self, $fh) = @_;
    $self->make_checksum_clean;

    my $packet = $self->make_byte_vector;
    $fh->print( $packet );

    return 1;
}

sub make_byte_vector
{
    my ($self) = @_;
    my $packet = pack 'n C C N n C*',
        $self->preamble,
        $self->version,
        $self->message_id,
        $self->payload_length,
        $self->checksum,
        $self->get_ordered_payload_value_bytes;
    return $packet;
}

sub get_ordered_payload_values
{
    my ($self) = @_;
    return map $self->$_, @{ $self->payload_fields };
}

sub get_ordered_payload_value_bytes
{
    my ($self) = @_;
    my @bytes;
    my %payload_fields_length = %{ $self->payload_fields_length };

    foreach my $field (@{ $self->payload_fields }) {
        $self->_logger->warn(
            "No entry for '$field' in $self->payload_fields_length"
        ) unless exists $payload_fields_length{$field};
        my $length = $payload_fields_length{$field} // 1;

        my $raw_value = $self->$field;
        $length = bytes::length( $raw_value )
            if $length == -1;
        my @raw_bytes;
        foreach (1 .. $length) {
            if( defined $raw_value) {
                my $value = $raw_value & 0xFF;
                push @raw_bytes, $value;
                $raw_value >>= 8;
            }
            else {
                push @raw_bytes, 0;
            }
        }

        push @bytes, reverse @raw_bytes;
    }

    return @bytes;
}

sub _calc_checksum
{
    my ($self) = @_;
    my @data = (
        $self->version,
        $self->message_id,
        $self->payload_length,
        $self->get_ordered_payload_value_bytes,
    );

    my ($check1, $check2) = UAV::Pilot->checksum_fletcher8( @data );
    my $checksum = ($check1 << 8) | $check2;
    $self->_set_checksum( $checksum );
    return 1;
}

sub make_checksum_clean
{
    my ($self) = @_;
    return 1 if $self->_is_checksum_clean;
    $self->_calc_checksum;
    $self->_is_checksum_clean( 1 );
    return 1;
}

sub make_packet_queue_map_key
{
    my ($self) = @_;
    # NOTE: any changes here must be reflected in
    # Packet::Ack::make_ack_packet_queue_key()
    my $key = join( $self->_PACKET_QUEUE_MAP_KEY_SEPERATOR,
        $self->checksum,
    );
    return $key;
}


sub _make_checksum_unclean
{
    my ($self) = @_;
    $self->_is_checksum_clean( 0 );
    return 1;
}


1;
__END__

=head1 NAME

  UAV::Pilot::Wumpus::Packet

=head1 DESCRIPTION

Role for Wumpus packets.  This is a custom protocol, documented below.

Do not create Packets directly.  Instead, use
C<UAV::Pilot::Wumpus::PacketFactory>.

Does the C<UAV::Pilot::Logger> role.

=head1 METHODS

=head2 write

    write( $fh )

Writes the packet to the given filehandle.

=head2 make_checksum_clean

Recalculates the checksum based on current field values.

=head2 make_byte_vector

Returns the packet fields in a single scalar full of bytes.

=head2 get_ordered_payload_vales

Returns the packet field values in the order they appear in C<payload_fields()>.

=head2 get_ordered_payload_value_bytes

Returns a byte array of all the packet fields in the order they appear in 
C<payload_fields()>.

=head1 make_packet_queue_map_key

Creates a unique key for this packet.

=head1 ATTRIBUTES

=head2 preamble

Fixed bytes that start every packet

=head2 version

Protocol version

=head2 checksum

Checksum value

=head1 REQUIRED METHODS/ATTRIBUTES

=head2 message_id

ID for this type of message

=head2 payload_fields

Arrayref.  A list of field names in the order they appear in the packet.

=head2 payload_length

Hashref.  Keys match to an entry in C<payload_fields>.  Values are the length 
in bytes of that field.

=head1 PROTOCOL

Each data packet starts with a 32-bit magic number (C<0xBF24>), which 
is followed by:

=over 4

=item * 1 byte - Version (this document is version 0x00)

=item * 1 byte - Message ID

=item * 4 bytes - Length of payload

=item * 2 bytes - Checksum of payload

=item * I<n> bytes - Payload

=back

The Message IDs are documented below.  The checksum field is calculated 
by taking the bytes of the fields for version, message ID, length, 
and payload,  and running Fletcher16 on them.

A session starts by the client sending a StartupRequest to the server. 
On getting a Startup response, the client should then send a RadioMinMax, 
followed by RadioOutput messages. During this time, the server can be 
sending Status and VideoStream messages. Either side may also send a 
AckRequest at any time, with the receiving end replying with Ack in a 
timely fashion.

=head2 Message IDs

=head3 0x00 Ack

Length 2. The response to an AckRequest.  Contains:

2 bytes - The checksum of the AckRequest being responded to.

=head3 0x01 AckRequest

Length 4. Requests that the reciever send an Ack in response. Contains:

4 bytes - Random data. This just gives something for the checksum to use.

=head3 0x02 RadioMinMax

Length 64. Sends the min/max values that will be sent by each channel. 
Contains:

=over 4 

=item * 2 bytes - ch1 min

=item * 2 bytes - ch2 min

=back

...

=over 4

=item * 2 bytes - ch16 min

=item * 2 bytes - ch1 max

=back

...

=over 4

=item * 2 bytes - ch16 max

=back

=head3 0x03 RadioOutputs

Length 32. Sends the current outputs for each channel. Contains:

=over 4

=item * 2 bytes - ch1 out

=item * 2 bytes - ch2 out

=back

...

=over 4

=item * 2 bytes - ch16 out

=back

=head3 0x04 Startup

Length 1. A response to a StartupRequest of the startup going well or not.
Contains:

1 byte - 0 = BAD, 1 = OK

=head3 0x05 StartupRequest

Length 0. Requests the server startup.

=head3 0x06 VideoStream

Length 9 + I<n>. A frame of video data.  Contains:

=over 4

=item * 1 byte - Codec ID. 0 = NULL, 1 = h.264, 2 = JPEG, other values reserved

=item * 2 bytes - Width

=item * 2 bytes - Height

=item * 4 bytes - Adler32 checksum of video data

=item * I<n> bytes - Video data

=back

=head3 0x07 Status

Length 4. Gives the current status. Contains:

=over 4

=item * 1 byte - Flags (see below)

=item * 1 byte - Battery level

=item * 2 bytes - Shield level

=back

Each bit of the flags field is:

=over 4

=item 0 Took a hit since last Status

=item 1 (Reserved)

=item 2 (Reserved)

=item 3 (Reserved)

=item 4 (Reserved)

=item 5 (Reserved)

=item 6 (Reserved)

=item 7 (Reserved)

=back

=cut
