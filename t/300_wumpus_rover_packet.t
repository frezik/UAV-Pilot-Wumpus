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
use Test::More tests => 95;
use strict;
use warnings;
use UAV::Pilot::Wumpus::PacketFactory;
use UAV::Pilot::Wumpus::Packet;
use UAV::Pilot::Exceptions;
use Test::Moose;


my $bad_header = make_packet( '3445', '01', '00000000', '00', '00000004', '030C',
    '01000000' );
eval {
    local $SIG{__WARN__} = sub {}; # Temporarily suppress warnings
    UAV::Pilot::Wumpus::PacketFactory->read_packet( $bad_header );
};
if( $@ && $@->isa( 'UAV::Pilot::Wumpus::Exception::BadHeader' ) ) {
    pass( 'Caught Bad Header exception' );
    cmp_ok( $@->got_header, '==', 0x3445, "BadHeader exception has got_header value" );
}
else {
    fail( 'Did not catch Bad Header exception (got: ' . $@ . ')' );
    fail( 'Fail matching magic number, too [placeholder failure for test count]' );
}

my $bad_checksum = make_packet(
    'BF24',   # Preamble
    '01',     # Version *
    '00000001',   # Packet count
    '00',     # Message ID *
    '00000002', # Length of Payload *
    '030D',   # Checksum (starred fields are fed into checksum)
    '0100', # Payload *
);
eval {
    local $SIG{__WARN__} = sub {}; # Temporarily suppress warnings
    UAV::Pilot::Wumpus::PacketFactory->read_packet( $bad_checksum );
};
if( $@ && $@->isa( 'UAV::Pilot::Wumpus::Exception::BadChecksum' ) ) {
    pass( 'Caught Bad Checksum exception' );
    cmp_ok( $@->got_checksum, '==', 0x030D, "BadChecksum exception has got_checksum value" );
    cmp_ok( $@->expected_checksum, '==', 0x040D, "BadChecksum exception has expected_checksum value" );
}
else {
    fail( 'Did not catch Bad Header exception (got: ' . $@ . ')' );
    fail( 'Fail got checksum, too [placeholder failure for test count]' );
    fail( 'Fail expected checksum, too [placeholder failure for test count]' );
}


my $good_packet = make_packet( 
    'BF24', '01', '00000002', '00', '00000002', '040D', '0100', );
my $packet = UAV::Pilot::Wumpus::PacketFactory->read_packet( $good_packet );
does_ok( $packet => 'UAV::Pilot::Wumpus::Packet' );
isa_ok( $packet => 'UAV::Pilot::Wumpus::Packet::Ack' );
cmp_ok( $packet->preamble,            '==', 0xBF24, "Preamble set" );
cmp_ok( $packet->packet_count,        '==', 0x0002, "Packet count set" );
cmp_ok( $packet->version,             '==', 0x01,   "Version set" );
cmp_ok( $packet->message_id,          '==', 0x00,   "Message ID set" );
cmp_ok( $packet->payload_length,      '==', 0x02,   "Payload length set" );
cmp_ok( $packet->checksum_received,  '==', 0x0100,   "Checksum Received" );


my $out = to_hex_string( write_packet( $packet ) );
cmp_ok( $out, 'eq', to_hex_string($good_packet),
    "Wrote packet data to filehandle" );


my $fresh_packet = UAV::Pilot::Wumpus::PacketFactory->fresh_packet(
    'Status' );
isa_ok( $fresh_packet => 'UAV::Pilot::Wumpus::Packet::Status' );
cmp_ok( $fresh_packet->message_id, '==', 0x07, "Message ID set" );

$fresh_packet->set_packet_count( 3 );
$fresh_packet->took_hit( 1 );
$fresh_packet->batt_level( 220 );
$fresh_packet->shield_level( 2**15 - 5 );
ok(! $fresh_packet->_is_checksum_clean, "Checksum no longer correct" );

my $expect_packet = make_packet( 'BF24', '01', '00000003', '07', '00000004', '63d6',
    '01DC7FFB' );
my $got_packet = to_hex_string( write_packet( $fresh_packet ) );
cmp_ok( $got_packet, 'eq', to_hex_string($expect_packet),
    "Wrote status packet" );
ok( $fresh_packet->_is_checksum_clean, "Checksum clean after write" );


my @TESTS = (
    # Each entry has 2 tests plus the number of keys in 'fields'
    {
        expect_class => 'StartupRequest',
        packet => make_packet( 'BF24', '01', '00000004', '05', '00000000', '060d' ),
        fields => {},
    },
    {
        expect_class => 'Startup',
        packet => make_packet( 'BF24', '01', '00000005', '04', '00000001',
            '0713', '01' ),
        fields => {
            ok => 0x01,
        },
    },
    {
        expect_class => 'RadioMinMax',
        packet => make_packet( 'BF24', '01', '00000006', '02', '00000040', '73e7',
            '0A', 'A0',
            '0B', 'B0',
            '0C', 'C0',
            '0D', 'D0',
            '0E', 'E0',
            '0F', 'F0',
            '00', '00',
            '01', '10',
            '0A', 'A0',
            '0B', 'B0',
            '0C', 'C0',
            '0D', 'D0',
            '0E', 'E0',
            '0F', 'F0',
            '00', '00',
            '01', '10',
            '0A', 'A0',
            '0B', 'B0',
            '0C', 'C0',
            '0D', 'D0',
            '0E', 'E0',
            '0F', 'F0',
            '00', '00',
            '01', '10',
            '0A', 'A0',
            '0B', 'B0',
            '0C', 'C0',
            '0D', 'D0',
            '0E', 'E0',
            '0F', 'F0',
            '00', '00',
            '01', '10',
        ),
        fields => {
            ch1_min => 0x0AA0,
            ch2_min => 0x0BB0,
            ch3_min => 0x0CC0,
            ch4_min => 0x0DD0,
            ch5_min => 0x0EE0,
            ch6_min => 0x0FF0,
            ch7_min => 0x0000,
            ch8_min => 0x0110,
            ch9_min => 0x0AA0,
            ch10_min => 0x0BB0,
            ch11_min => 0x0CC0,
            ch12_min => 0x0DD0,
            ch13_min => 0x0EE0,
            ch14_min => 0x0FF0,
            ch15_min => 0x0000,
            ch16_min => 0x0110,
            ch1_max => 0x0AA0,
            ch2_max => 0x0BB0,
            ch3_max => 0x0CC0,
            ch4_max => 0x0DD0,
            ch5_max => 0x0EE0,
            ch6_max => 0x0FF0,
            ch7_max => 0x0000,
            ch8_max => 0x0110,
            ch9_max => 0x0AA0,
            ch10_max => 0x0BB0,
            ch11_max => 0x0CC0,
            ch12_max => 0x0DD0,
            ch13_max => 0x0EE0,
            ch14_max => 0x0FF0,
            ch15_max => 0x0000,
            ch16_max => 0x0110,
        },
    },
    {
        expect_class => 'RadioOutputs',
        packet => make_packet( 'BF24', '01', '00000007', '03', '00000020', '3c19',
            '0A', 'A0',
            '0B', 'B0',
            '0C', 'C0',
            '0D', 'D0',
            '0E', 'E0',
            '0F', 'F0',
            '00', '00',
            '01', '10',
            '0A', 'A0',
            '0B', 'B0',
            '0C', 'C0',
            '0D', 'D0',
            '0E', 'E0',
            '0F', 'F0',
            '00', '00',
            '01', '10',
        ),
        fields => {
            ch1_out => 0x0AA0,
            ch2_out => 0x0BB0,
            ch3_out => 0x0CC0,
            ch4_out => 0x0DD0,
            ch5_out => 0x0EE0,
            ch6_out => 0x0FF0,
            ch7_out => 0x0000,
            ch8_out => 0x0110,
            ch9_out => 0x0AA0,
            ch10_out => 0x0BB0,
            ch11_out => 0x0CC0,
            ch12_out => 0x0DD0,
            ch13_out => 0x0EE0,
            ch14_out => 0x0FF0,
            ch15_out => 0x0000,
            ch16_out => 0x0110,
        },
    },
    {
        expect_class => 'AckRequest',
        packet => make_packet( 'BF24', '01', '00000008', '01', '00000004', '0c2e',
            '01010202', ),
        fields => {
            payload_data => 0x01010202,
        },
    },
    {
        expect_class => 'Ack',
        packet => make_packet( 'BF24', '01', '00000009', '00', '00000002', '050e',
            '0101', ),
        fields => {
            checksum_received=> 0x0101,
        },
    },
    {
        expect_class => 'VideoStream',
        packet => make_packet( 'BF24', '01', '0000000A', '06', '0000000A', 'dca2',
            '00', '0010', '0010', '11223344', '01', ),
        fields => {
            codec => 0x00,
            width => 0x0010,
            height => 0x0010,
            adler32_checksum => 0x11223344,
            payload => 0x01,
        },
    },
    {
        expect_class => 'Status',
        packet => make_packet( 'BF24', '01', '0000000B', '07', '00000004', '63d6',
            '01DC7FFB' ),
        fields => {
            flags => 0x01,
            batt_level => 0xDC,
            shield_level => 0x7FFB,
        },
    },
);
my $CLASS_PREFIX = 'UAV::Pilot::Wumpus::Packet::';
my $test_i = 0;
foreach (@TESTS) {
    my $packet_data = $_->{packet};
    my %fields = %{ $_->{fields} };
    my $short_class  = $_->{expect_class};
    my $expect_class = $CLASS_PREFIX . $short_class;

    my $packet = UAV::Pilot::Wumpus::PacketFactory->read_packet(
        $packet_data );
    isa_ok( $packet => $expect_class );

    foreach my $field (keys %fields ) {
        cmp_ok( $packet->$field, '==', $fields{$field},
            "$short_class->$field matches" );
    }

    my $got_packet = to_hex_string( write_packet( $packet ) );
    my $expect_packet = to_hex_string( $packet_data );
    cmp_ok( $got_packet, 'eq', $expect_packet,
        "$short_class writes packet correctly" );
}

my $too_long_packet = make_packet( 'BF24', '01', '0000000C', '01', '00000001', '040a', 
    '01123401C20000' );
my $long_packet = UAV::Pilot::Wumpus::PacketFactory->read_packet(
    $too_long_packet );
cmp_ok( $long_packet->checksum, '==', 0x040a,
    'Checksum correct for long packet' );


sub write_packet
{
    my ($packet) = @_;
    my $out = '';

    open( my $fh, '>', \$out ) or die "Can't open ref to scalar: $!\n";
    $packet->write( $fh );
    close $fh;

    return $out;
}

sub make_packet
{
    my (@hex_str) = @_;
    pack 'H*', join( '', @hex_str );
}

sub to_hex_string
{
    my ($str) = @_;
    my @str = unpack 'C*', $str;
    return join '', '0x', map( { sprintf '%02x', $_ } @str );
}
