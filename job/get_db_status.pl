#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: get_db_status.pl
#
#        USAGE: ./get_db_status.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Mingshi (deepwarm.com), fivemingshi@gmail.com
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 2014/01/21 13时02分36秒
#     REVISION: ---
#===============================================================================

use Modern::Perl;
use utf8;
use strict;
use warnings;
use Try::Tiny;

use File::Basename 'dirname';
use File::Spec::Functions qw(catdir splitdir);

use lib '../../lib';
use Mojo::Base 'Mojolicious';
use MY::Controller;

use Text::Xslate::Util qw/mark_raw/;
use Mojo::Util qw/url_escape camelize md5_sum encode/;
use Mojo::JSON;
use JSON::XS;
use MY::Utils;

use Data::Dumper;

################
#  ENV CONFIG  #
################

my @localHost = ("mingshi-hacking.local","hahhaha");
my $hostName = `uname -a|awk '{print \$2}'`;
chomp($hostName);

if (@localHost ~~ /^$hostName$/) {
    $ENV{ENV} = 'local';
} else {
    $ENV{ENV} = 'product';
}

################
#  DB CONFIG  #
################

$ENV{DBI_DATABASE} = 'imot';
$ENV{DBI_USER} = 'root';
$ENV{DBI_HOST} = '127.0.0.1';
if ($ENV{ENV} eq "local") {
    $ENV{DBI_PASSWORD} = '';
} else {
    $ENV{DBI_PASSWORD} = 'thisisme!';
}

my @servers = M('dbmo_server')->select({},{})->all;


# process DB config into mysql use multiple threads
use threads;
use threads::shared;

my @threads;
for my $server (@servers) {
    push @threads, threads->create(
        \&doProcess,
        $server->{data}
    ); 
}

$_->join for @threads;

sub doProcess {
    my ($server) = @_;
    
    try {
        my $res;
        unless ($server->{db_passwd}) {
            $res = `mysql -h$server->{server} -P$server->{port} -u$server->{db_user} -e ""`
        } else {
            my $res = `mysql -u$server->{db_user} -p`
        }
    } catch {
        my $s = $server->{server} . ":" . $server->{port};
        warn "can't get the $s status";
    }
}
