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
use Test::More tests => 9;
use v5.14;
use UAV::Pilot::Wumpus::Driver::Mock;
use Test::Moose;

my $wumpus = UAV::Pilot::Wumpus::Driver::Mock->new({
    host => 'localhost',
    port => 49005,
});
isa_ok( $wumpus => 'UAV::Pilot::Wumpus::Driver' );
does_ok( $wumpus => 'UAV::Pilot::Driver' );
cmp_ok( $wumpus->port, '==', 49005, "Port set" );

ok( $wumpus->connect, "Connect to Wumpus" );
my $startup_request_packet = $wumpus->last_sent_packet;
isa_ok( $startup_request_packet
    => 'UAV::Pilot::Wumpus::Packet::StartupRequest' );

$wumpus->send_radio_output_packet( 150 );
my $radio1_packet = $wumpus->last_sent_packet;
isa_ok( $radio1_packet => 'UAV::Pilot::Wumpus::Packet::RadioOutputs' );
cmp_ok( $radio1_packet->ch1_out, '==', 150, "Channel1 set" );

$wumpus->send_radio_output_packet( 150, 70 );
my $radio2_packet = $wumpus->last_sent_packet;
cmp_ok( $radio2_packet->ch1_out, '==', 150, "Channel1 set" );
cmp_ok( $radio2_packet->ch2_out, '==', 70,  "Channel2 set" );

# TODO read packets, handle AckRequest
