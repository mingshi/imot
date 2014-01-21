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
use DBI;
use File::Read;

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

my $dataDir = "data/";

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
        my $sql = 'SELECT VARIABLE_NAME, VARIABLE_VALUE FROM GLOBAL_STATUS WHERE VARIABLE_NAME IN ("CONNECTIONS","SLOW_QUERIES","COM_SELECT","COM_INSERT","COM_UPDATE","COM_DELETE")';
        my $dbh = DBI->connect("DBI:mysql:information_schema;host=$server->{server};port=$server->{port}", "$server->{db_user}", "$server->{db_passwd}");
        
        if ($dbh) {
            my $sth = $dbh->prepare($sql);
            $sth->execute();
            
            while (my $ref = $sth->fetchrow_hashref()) {
                my $file = $dataDir . $server->{server} . "-" . $server->{port} . "-" . $ref->{VARIABLE_NAME} ;
                my $oldData;

                if (-e $file) {
                    $oldData = read_file($file);
                }

                unless ($oldData && $oldData <= $ref->{VARIABLE_VALUE}) {
                    my $ins = {
                        sid =>  $server->{id},
                        v_type  =>  $ref->{VARIABLE_NAME},
                        value   =>  0
                    };

                    M('dbmo_value')->insert($ins);

                } else {
                    my $newData;
                    unless ($oldData) {
                        $newData = 0;
                    } else {
                        $newData = $ref->{VARIABLE_VALUE} - $oldData;
                    }
                    
                    my $ins = {
                        sid =>  $server->{id},
                        v_type  =>  $ref->{VARIABLE_NAME},
                        value   =>  $newData,
                    };
                    M('dbmo_value')->insert($ins);
                }


                open (MYFILE, ">:utf8", $file);
                print MYFILE $ref->{VARIABLE_VALUE};
                close MYFILE;
            }
        }
        
        $dbh->disconnect();
    } catch {
        my $s = $server->{server} . ":" . $server->{port};
        warn "can't get the $s status";
    }
}
