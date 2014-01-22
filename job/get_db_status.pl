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
use DBIx::Custom;
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
    $ENV{DBI_PORT} = 3306;
} else {
    $ENV{DBI_PASSWORD} = 'thisisme!';
    $ENV{DBI_PORT} = 3308;
}

my @servers = M('dbmo_server')->select({},{})->all;


# process DB config into mysql use multiple threads
use threads;

my @threads;
for my $server (@servers) {
    push @threads, threads->create(
        \&doProcess,
        $server->{data}
    ); 
}

$_->join for @threads;

#use DBIx::Custom;
#use AnyEvent;
#
#my $cond = AnyEvent->condvar;
#
#for my $server (@servers) {
#    my $dbi = DBIx::Custom->connect(
#        dsn     =>  "dbi:mysql:database=information_schema;host=$server->{data}{server};port=$server->{data}{port}",
#        user    =>  $server->{data}{db_user},
#        password    =>  $server->{data}{db_passwd},
#        option  =>  {
#            mysql_enable_utf8 => 1,
#            quote_char => '`',
#        },
#        connector   => 1,
#    );
#   
#    $dbi->select(
#        column  =>  ['VARIABLE_NAME', 'VARIABLE_VALUE'],
#        table   =>  'GLOBAL_STATUS',
#        where   =>  {'VARIABLE_NAME' => ['CONNECTIONS','SLOW_QUERIES','COM_SELECT','COM_INSERT','COM_UPDATE','COM_DELETE']},
#        prepare_attr => {async => 1},
#        async => sub {
#        }
#    );
#}
#
#$cond->recv;

sub doProcess {
    my ($server) = @_;
    
    try {
        
        create_curr_table();

        my $tmpDbh = DBIx::Custom->connect(
            dsn     =>  "dbi:mysql:database=information_schema;host=$server->{server};port=$server->{port}",
            user    =>  $server->{db_user},
            password    =>  $server->{data}{db_passwd},
            option  =>  {
                mysql_enable_utf8 => 1,
                quote_char => '`',
            },
            connector   => 1,
        );
        
        if ($tmpDbh) {
            my $result = $tmpDbh->select(
                column  =>  ['VARIABLE_NAME', 'VARIABLE_VALUE'],
                table   =>  'GLOBAL_STATUS',
                where   =>  {'VARIABLE_NAME' => ['CONNECTIONS','SLOW_QUERIES','COM_SELECT','COM_INSERT','COM_UPDATE','COM_DELETE']}
            )->all;

            for my $ref (@$result) {
                my $file = $dataDir . $server->{server} . "-" . $server->{port} . "-" . $ref->{VARIABLE_NAME} . ".log" ;
                my $oldData;

                if (-e $file) {
                    $oldData = read_file($file);
                }
                
                my $ins;

                unless ($oldData && $oldData <= $ref->{VARIABLE_VALUE}) {
                    $ins = {
                        sid =>  $server->{id},
                        v_type  =>  $ref->{VARIABLE_NAME},
                        value   =>  0
                    };

                } else {
                    my $newData;
                    unless ($oldData) {
                        $newData = 0;
                    } else {
                        $newData = $ref->{VARIABLE_VALUE} - $oldData;
                    }
                    
                    $ins = {
                        sid =>  $server->{id},
                        v_type  =>  $ref->{VARIABLE_NAME},
                        value   =>  $newData,
                    };
                }
                
                my $insDbi = DBIx::Custom->connect(
                    dsn         =>  "dbi:mysql:database=$ENV{DBI_DATABASE};host=$ENV{DBI_HOST};port=$ENV{DBI_PORT}",
                    user        =>  $ENV{DBI_USER},
                    password    =>  $ENV{DBI_PASSWORD},
                );
                
                my $today = strftime("%Y%m%d", time());
                my $table = "dbmo_value_" . $today;
                
                $insDbi->insert($ins, table => $table);
                
                $insDbi->disconnect();

                open (MYFILE, ">:utf8", $file);
                print MYFILE $ref->{VARIABLE_VALUE};
                close MYFILE;
            }
        }
        
        $tmpDbh->disconnect();
    } catch {
        my $s = $server->{server} . ":" . $server->{port};
        warn "can't get the $s status";
    }
}

sub create_curr_table {
    my $today = strftime("%Y%m%d", time());
    my $table = "dbmo_value_" . $today;
   
    my $createDbi = DBIx::Custom->connect(
        dsn         =>  "dbi:mysql:database=$ENV{DBI_DATABASE};host=$ENV{DBI_HOST};port=$ENV{DBI_PORT}",
        user        =>  $ENV{DBI_USER},
        password    =>  $ENV{DBI_PASSWORD},
    );
   
    $createDbi->execute(
        "CREATE TABLE IF NOT EXISTS `$table` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `sid` int(11) NOT NULL DEFAULT '0',
        `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `v_type` varchar(50) NOT NULL,
        `value` varchar(50) NOT NULL DEFAULT '0',
        PRIMARY KEY (`id`),
        KEY `searchsid` (`sid`,`v_type`,`create_time`)
        ) ENGINE=InnoDB AUTO_INCREMENT=175 DEFAULT CHARSET=utf8" 
    );
    
    $createDbi->disconnect();
}
