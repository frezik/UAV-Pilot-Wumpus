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
package UAV::Pilot::Wumpus::Packet::Status;

use v5.14;
use Moose;
use namespace::autoclean;


use constant {
    payload_length => 4,
    message_id     => 0x07,
    payload_fields => [qw{
        flags
        batt_level
        shield_level
    }],
    payload_fields_length => {
        flags => 1,
        batt_level => 1,
        shield_level => 2,
    },
};


has 'flags' => (
    is  => 'ro',
    isa => 'Int',
    writer => '_set_flags',
);
has 'batt_level' => (
    is  => 'rw',
    isa => 'Int',
);
has 'shield_level' => (
    is  => 'rw',
    isa => 'Int',
);

sub took_hit
{
    my $self = shift;
    my $flags = $self->flags;
    
    if( @_ ) {
        my $took_hit = shift;
        $flags &= (0xFF ^ 0x01);
        $flags |= ($took_hit << 0);
        $self->_set_flags( $flags );
    }

    return $flags;
}

with 'UAV::Pilot::Wumpus::Packet';


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

