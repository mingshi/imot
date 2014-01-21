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
use List::MoreUtils qw/uniq/;
use Scalar::Util qw/looks_like_number/;
use Mojo::JSON;
use JSON::XS;
use Data::Dumper;

sub db_list {
    my $self = shift;
    
    my $where = {};
    my $attrs = {
        'order_by'  =>  '-create_time',
    };
    
    $self->set_list_data('dbmo_server', $where, $attrs);

    $self->render('dbmo/db_list');
}

sub add_db {
    my $self = shift;
    unless ($self->_check_admin) {
        return $self->fail("你没有权限", go => 'dbmo/db_list');
    }
    $self->render('dbmo/add_db');
}

sub save {
    my $self = shift;
    
    unless ($self->_check_admin) {
        return $self->fail("你没有权限", go => 'dbmo/db_list');
    }

    my %params = $self->param_request({
        server  =>  'STRING' ,
        port    =>  'UINT',
        db_user =>  'STRING',
        db_passwd   =>  'STRING',
    });

    my $rules = [
        'server|DB IP Address'  =>  "required|valid_ip",
        'port|DB Port'  =>  "required|integer",
        'db_user|DB User'   =>  'required'
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
    $ins->{db_user} = $params{db_user};
    $ins->{db_passwd} = $params{db_passwd};
    
    M('dbmo_server')->insert($ins);
    
    $self->succ('添加成功', go => 'db_list');
}

sub _check_admin {
    my $self = shift;

    return $self->current_user->{info}{is_admin} == 1;
}

1;
