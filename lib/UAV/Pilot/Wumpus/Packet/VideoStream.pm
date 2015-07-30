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
package UAV::Pilot::Wumpus::Packet::VideoStream;

use v5.14;
use Moose;
use namespace::autoclean;


use constant {
    base_payload_length => 9,
    message_id     => 0x06,
    payload_fields => [qw{
        codec
        width
        height
        adler32_checksum
        payload
    }],
    payload_fields_length => {
        codec => 1,
        width => 2,
        height => 2,
        adler32_checksum => 4,
        payload => -1,
    },
};


has 'codec' => (
    is  => 'rw',
    isa => 'Int',
);
has 'width' => (
    is  => 'rw',
    isa => 'Int',
);
has 'height' => (
    is  => 'rw',
    isa => 'Int',
);
has 'adler32_checksum' => (
    is  => 'rw',
    isa => 'Int',
);
has 'payload' => (
    is  => 'rw',
    isa => 'Int',
);

sub payload_length
{
    my ($self) = @_;
    my $base_len = $self->base_payload_length;
    use bytes;
    return $base_len + bytes::length( $self->payload );
}


with 'UAV::Pilot::Wumpus::Packet';


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

