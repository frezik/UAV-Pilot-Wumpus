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
use UAV::Pilot::Exceptions;

package UAV::Pilot::Wumpus::Exception::BadHeader;

use v5.14;
use Moose;
use namespace::autoclean;
extends 'UAV::Pilot::Exception';

has 'got_header' => (
    is => 'ro',
    isa => 'Int',
);

no Moose;
__PACKAGE__->meta->make_immutable;


package UAV::Pilot::Wumpus::Exception::BadChecksum;

use v5.14;
use Moose;
use namespace::autoclean;
extends 'UAV::Pilot::Exception';


has 'got_checksum' => (
    is => 'ro',
    isa => 'Int',
);
has 'expected_checksum' => (
    is => 'ro',
    isa => 'Int',
);

sub to_string
{
    my ($self) = @_;
    return "BadChecksum: Expected checksum ("
        . $self->expected_checksum . "), got checksum ("
        . $self->got_checksum . ")";
}


no Moose;
__PACKAGE__->meta->make_immutable;


1;
__END__


=head1 NAME

  UAV::Pilot::Wumpus::Exceptions

=head1 DESCRIPTION

Exceptions that could be thrown by C<UAV::Pilot::Wumpus> modules.  All 
inherit from C<UAV::Pilot::Exception>, which does the role C<Throwable>.

=head1 EXCEPTIONS

=head2 UAV::Pilot::Wumpus::Exception::BadHeader

=head2 UAV::Pilot::Wumpus::Exception::BadChecksum

=cut
