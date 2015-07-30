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
package UAV::Pilot::Wumpus::Packet::RadioMinMax;

use v5.14;
use Moose;
use namespace::autoclean;


use constant {
    payload_length => 64,
    message_id     => 0x02,
    payload_fields => [qw{
        ch1_max
        ch2_max
        ch3_max
        ch4_max
        ch5_max
        ch6_max
        ch7_max
        ch8_max
        ch9_max
        ch10_max
        ch11_max
        ch12_max
        ch13_max
        ch14_max
        ch15_max
        ch16_max
        ch1_min
        ch2_min
        ch3_min
        ch4_min
        ch5_min
        ch6_min
        ch7_min
        ch8_min
        ch9_min
        ch10_min
        ch11_min
        ch12_min
        ch13_min
        ch14_min
        ch15_min
        ch16_min
    }],
    payload_fields_length => {
        ch1_max => 2,
        ch2_max => 2,
        ch3_max => 2,
        ch4_max => 2,
        ch5_max => 2,
        ch6_max => 2,
        ch7_max => 2,
        ch8_max => 2,
        ch9_max => 2,
        ch10_max => 2,
        ch11_max => 2,
        ch12_max => 2,
        ch13_max => 2,
        ch14_max => 2,
        ch15_max => 2,
        ch16_max => 2,
        ch1_min => 2,
        ch2_min => 2,
        ch3_min => 2,
        ch4_min => 2,
        ch5_min => 2,
        ch6_min => 2,
        ch7_min => 2,
        ch8_min => 2,
        ch9_min => 2,
        ch10_min => 2,
        ch11_min => 2,
        ch12_min => 2,
        ch13_min => 2,
        ch14_min => 2,
        ch15_min => 2,
        ch16_min => 2,
    },
};

has 'ch1_max' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch2_max' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch3_max' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch4_max' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch5_max' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch6_max' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch7_max' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch8_max' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch9_max' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch10_max' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch11_max' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch12_max' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch13_max' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch14_max' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch15_max' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch16_max' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch1_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch2_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch3_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch4_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch5_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch6_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch7_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch8_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch9_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch10_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch11_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch12_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch13_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch14_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch15_min' => (
    is  => 'rw',
    isa => 'Int',
);
has 'ch16_min' => (
    is  => 'rw',
    isa => 'Int',
);

with 'UAV::Pilot::Wumpus::Packet';


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

