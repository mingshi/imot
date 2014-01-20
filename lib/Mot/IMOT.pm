#
#===============================================================================
#
#         FILE: IMOT.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Mingshi (deepwarm.com), fivemingshi@gmail.com
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 2014/01/20 13时42分34秒
#     REVISION: ---
#===============================================================================
package Mot::IMOT;

use strict;
use warnings;
 
use Mojo::Base 'Mojolicious';
use MY::Controller;
use Text::Xslate::Util qw/mark_raw/;
use Mojo::Util qw/url_escape camelize md5_sum encode/;
use Mojo::JSON;
use JSON::XS;
use MY::Utils;
use utf8;

sub startup {
    my $self = shift;

    my @localHost = ("mingshi-hacking.local","hahhaha");
    my $hostName = `uname -a|awk '{print \$2}'`;
    chomp($hostName);

    if (@localHost ~~ /^$hostName$/) {
        $ENV{ENV} = 'local';
    } else {
        $ENV{ENV} = 'product';
    }

    $self->secret("Dancing with the linux");
    $self->controller_class("MY::Controller");

    push @{$self->static->paths}, $self->home->rel_dir('../public');
    push @{$self->plugins->namespaces}, 'Mot::IMOT::Plugin';
    

}
