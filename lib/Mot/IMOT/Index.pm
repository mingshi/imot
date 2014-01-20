#
#===============================================================================
#
#         FILE: Index.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Mingshi (deepwarm.com), fivemingshi@gmail.com
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 2014/01/20 15时52分33秒
#     REVISION: ---
#===============================================================================
package Mot::IMOT::Index;

use strict;
use warnings;
use Mojo::Base 'MY::Controller';
use utf8;

sub index {
    my $self = shift;
    $self->redirect_to('/dbmo/db_list');
    return;
}

1;

