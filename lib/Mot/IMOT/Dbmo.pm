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

sub save {
    my $self = shift;
    my %params = $self->param_request({
        server  =>  'STRING' ,
        port    =>  'UINT'
    });

    my $rules = [
        'server|DB IP Address'  =>  "required|valid_ip",
        'port|DB Port'  =>  "required|integer",
    ];

    my $rule_checks = {
        valid_ip    =>  sub {
            unless ($_[0] ~~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
                return "IP填写有误";
            }
            return undef;
        }
    };

    unless ($self->form_validation($rules, $rule_checks)) {
        return $self->fail($self->validation_error);
    }

    # check if exists
    my $already = M('dbmo_server')->find({
        server  =>  $params{server},
        port    =>  $params{port}
    });

    if ($already) {
        return $self->fail('已经存在该数据库');
    }
    
    my $ins = $self->validation_data;
    
    $ins->{server} = $params{server};
    $ins->{port} = $params{port};
    
    M('dbmo_server')->insert($ins);
    
    $self->succ('添加成功', go => 'db_list');
}

1;
