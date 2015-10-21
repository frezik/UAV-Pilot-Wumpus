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
package UAV::Pilot::Wumpus::PacketFactory;

use v5.14;
use warnings;
use UAV::Pilot;
use UAV::Pilot::Wumpus::Exceptions;
use UAV::Pilot::Wumpus::Packet;
use UAV::Pilot::Wumpus::Packet::Ack;
use UAV::Pilot::Wumpus::Packet::AckRequest;
use UAV::Pilot::Wumpus::Packet::RadioMinMax;
use UAV::Pilot::Wumpus::Packet::RadioOutputs;
use UAV::Pilot::Wumpus::Packet::Startup;
use UAV::Pilot::Wumpus::Packet::StartupRequest;
use UAV::Pilot::Wumpus::Packet::Status;
use UAV::Pilot::Wumpus::Packet::VideoStream;


use constant PACKET_CLASS_PREFIX  => 'UAV::Pilot::Wumpus::Packet::';
use constant PREAMBLE             => 0xBF24;
use constant MESSAGE_ID_CLASS_MAP => {
    0x00 => 'Ack',
    0x01 => 'AckRequest',
    0x02 => 'RadioMinMax',
    0x03 => 'RadioOutputs',
    0x04 => 'Startup',
    0x05 => 'StartupRequest',
    0x06 => 'VideoStream',
    0x07 => 'Status',
};


sub read_packet
{
    my ($self, $packet) = @_;
    my ($preamble, $version, $packet_count, $message_id, $payload_length,
        , $checksum, @payload) = unpack 'n C N C N n C*', $packet;
    UAV::Pilot::Wumpus::Exception::BadHeader->throw({
        got_header => $preamble,
    }) if $self->PREAMBLE != $preamble;

    # Cut off payload if we get more than expected
    $payload_length = scalar(@payload) if $payload_length >= scalar(@payload);
    @payload = @payload[0 .. $payload_length - 1];

    my ($expect_checksum1, $expect_checksum2)
        = UAV::Pilot->checksum_fletcher8(
            $version, $message_id, $payload_length, @payload );
    my $expect_checksum = ($expect_checksum1 << 8) | $expect_checksum2;
    UAV::Pilot::Wumpus::Exception::BadChecksum->throw({
        got_checksum => $checksum,
        expected_checksum => $expect_checksum,
    }) if $expect_checksum != $checksum;

    if(! exists $self->MESSAGE_ID_CLASS_MAP->{$message_id}) {
        warn sprintf( 'No class found for message ID 0x%02x', $message_id )
            . "\n";
        return undef;
    }
    my $class = $self->PACKET_CLASS_PREFIX
        . $self->MESSAGE_ID_CLASS_MAP->{$message_id};
    my $new_packet = $class->new({
        preamble  => $preamble,
        packet_count => $packet_count,
        version   => $version,
        checksum => $checksum,
        payload   => \@payload,
    });
    return $new_packet;
}

sub fresh_packet
{
    my ($self, $type) = @_;
    my $class = $self->PACKET_CLASS_PREFIX . $type;

    my $packet = eval {
        $class->new({
            fresh => 1,
        });
    };
    if( $@ ) {
        die "[PacketFactory] Could not init '$class': $@\n";
    }

    return $packet;
}


1;
__END__

=head1 NAME

  UAV::Pilot::Wumpus::PacketFactory

=head1 SYNOPSIS

    # Where $packet_in is a bunch of bytes read from the network:
    my $packet = UAV::Pilot::Wumpus::PacketFactory->read_packet(
        $packet_in );

    # Create a fresh packet that we might later send over the network:
    my $new_packet = UAV::Pilot::Wumpus::PacketFactory->fresh_packet(
        'Ack' );

=head1 DESCRIPTION

Creates new packets, either for reading a bunch of bytes off the network, or 
for fresh ones that we'll send back over the network.

=head1 METHODS

=head2 read_packet

    read_packet( $bytes )

Takes a bunch of bytes and returns a C<UAV::Pilot::Wumpus::Packet> object 
based on that data.

=head2 fresh_packet

    fresh_packet( $type )

Creates a new packet based on C<$type> and returns it.  The C<$type> parameter 
should be one of the classes under C<UAV::Pilot::Wumpus::Packet::>, such 
as C<Ack> or C<RadioOutputs>.

=cut
