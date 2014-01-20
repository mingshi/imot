#
#===============================================================================
#
#         FILE: Dbmo.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Mingshi (deepwarm.com), fivemingshi@gmail.com
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 2014/01/20 15时54分25秒
#     REVISION: ---
#===============================================================================
package Mot::IMOT::Dbmo;

use strict;
use warnings;
 
use Mojo::Base 'MY::Controller';
use Mojo::Util qw/encode/;
use MY::Utils;
use MY::Data;
use List::MoreUtils qw/uniq/;
use Scalar::Util qw/looks_like_number/;
use Mojo::JSON;
use JSON::XS;
use Data::Dumper;

sub db_list {
    my $self = shift;
    $self->render('dbmo/db_list');
}

sub add_db {
    my $self = shift;
    $self->render('dbmo/add_db');
}

1;
