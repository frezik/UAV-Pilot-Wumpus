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
use Test::More;
use strict;
use warnings;
use AnyEvent;
use UAV::Pilot::Control;
use UAV::Pilot::ControlRover;
use UAV::Pilot::EasyEvent;
use UAV::Pilot::Wumpus::Driver::Mock;
use UAV::Pilot::Wumpus::PacketFactory;
use Test::Moose;

eval "
    use UAV::Pilot::Wumpus::Control::Event;
";
if( $@ ) {
    plan skip_all => "UAV::Pilot::SDL not installed";
}
else {
    plan tests => 4;
}


my $driver = UAV::Pilot::Wumpus::Driver::Mock->new({
    host => 'localhost',
    port => 49000,
});
$driver->connect;

my $control = UAV::Pilot::Wumpus::Control::Event->new({
    driver => $driver,
});
isa_ok( $control => 'UAV::Pilot::Wumpus::Control::Event' );
isa_ok( $control => 'UAV::Pilot::Wumpus::Control' );

my $cv = AnyEvent->condvar;
my $event = UAV::Pilot::EasyEvent->new({
    condvar => $cv,
});
$control->init_event_loop( $cv, $event );

my $ack_recv = 0;
my $checksum_match = 0;
$event->add_event( 'ack_recv' => sub {
    my ($sent_packet, $ack_packet) = @_;
    $ack_recv++;
    $checksum_match++
        if $sent_packet->checksum == $ack_packet->checksum_received;
});

my $write_time = $control->CONTROL_UPDATE_TIME;
my $write_duration = $write_time * 2 + ($write_time / 2);
my $test_timer; $test_timer = AnyEvent->timer(
    after => $write_duration,
    cb => sub {
        cmp_ok( $ack_recv, '>', 1, "Ack control packets" );
        cmp_ok( $checksum_match, '==', $ack_recv, "Checksum matched up" );
        $cv->send;
        $test_timer;
    },
);
my $send_timer; $send_timer = AnyEvent->timer(
    after => $write_time,
    cb => sub {
        $control->throttle( 100 );
        $control->roll( 50 );
        $send_timer;
    },
);
$cv->recv;
