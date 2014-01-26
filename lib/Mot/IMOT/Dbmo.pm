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
use Text::Xslate::Util qw/mark_raw/;
use MY::Utils;
use List::MoreUtils qw/uniq/;
use Scalar::Util qw/looks_like_number/;
use Mojo::JSON;
use JSON::XS;
use Data::Dumper;
use Date::Parse;
use URI::Escape;

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

sub detail {
    my $self = shift;
    my %params = $self->param_request({
        id  =>  'UINT',
        start_time  =>  'STRING',
        end_time    =>  'STRING',
    });
    
    my $db = M('dbmo_server')->find($params{id});
    
    my ($start_time, $end_time);

    unless ($params{start_time}) {
        $start_time = strftime("%Y-%m-%d %H:%M", time() - 10 * 60);
    } else {
        $start_time = $params{start_time};
    }
    unless ($params{end_time}) {
        $end_time = strftime("%Y-%m-%d %H:%M", time());
    } else {
        $end_time = $params{end_time};
    }
  
    my @dates = get_tables_by_date($start_time, $end_time);
  
    if ($end_time lt $start_time) {
        return $self->fail('结束时间必须大于开始时间', go => "/dbmo/detail?id=" . $params{id});
    }
   
    if (my $days = @dates > 7) {
        return $self->fail('最多选择7天内的查询', go => "/dbmo/detail?id=" . $params{id})
    }
   
    my @cates;
    my @series;
    my $tmpData = {};

    for my $stepDate (@dates) {
        my $table = "dbmo_value_" . $stepDate;
        my @result = M("$table")->select({
            -and    =>  [
                'sid'   =>  $params{id},
                'create_time'   =>  {'>='   =>  "$start_time"},
                'create_time'   =>  {'<='   =>  "$end_time"}
            ]    
        },{
            'order_by'  =>  'create_time',
        })->all;
        

        for my $res (@result) {
            my $val = strftime("%Y-%m-%d %H:%M", str2time($res->{data}{create_time}));
            unless ($val ~~ @cates) {
                push @cates, $val;
            }
            
            my $tKey = strftime("%Y-%m-%d %H:%M", str2time("$res->{data}{create_time}"));
            $tmpData->{$res->{data}{v_type}}->{$tKey} = $res->{data}{value};
        }
    }
  
    my @types;
    foreach my $key (keys %$tmpData) {
        push @types, $key;
    }

    for my $type (@types) {
        my $tmpV;
        $tmpV->{name} = $type;
        my @tmpArr;
        for my $cate (@cates) {
            my $tmpValue;
            $tmpValue = $tmpData->{$type}->{$cate} ? int($tmpData->{$type}->{$cate}) : 0;
            
            push @tmpArr, $tmpValue;
        }
        @{$tmpV->{data}} = @tmpArr;
        
        push @series, $tmpV;
    }
    
    my %data = (
        db  =>  $db,
        start_time  =>  $start_time,
        end_time    =>  $end_time,
        cates       =>  mark_raw(encode_json(\@cates)),
        series      => mark_raw(encode_json(\@series))
    );

    $self->render('dbmo/detail', %data);
}

sub delete {
    my $self = shift;
    my %params = $self->param_request({
        id  =>  'UINT',    
    });
    
    unless ($self->_check_admin) {
        return $self->fail("你没有权限", go => 'dbmo/db_list');    
    }

    my $dbserver = M('dbmo_server')->find($params{id});
    unless ($dbserver) {
        return $self->fail("没有该DB", go => 'dbmo/db_list');
    }

    my $where = ({
        id  =>  $params{id},
    });

    my $res = M('dbmo_server')->delete($params{id});

    return $self->succ('删除成功', go => 'dbmo/db_list');
}

##########################
#根据时间日期获得分表表名#
##########################
sub get_tables_by_date {
    my ($startTime, $endTime) = @_;
    
    my $start = strftime('%Y%m%d', str2time("$startTime"));

    my $end = strftime('%Y%m%d', str2time("$endTime"));
    
    my @dates;

    my $t = $start;

    push @dates, $t;

    while ($t < $end) {
        my $tamp = str2time("$t") + 24 * 60 * 60;
        my $d = strftime('%Y%m%d', $tamp);
        push @dates, $d;
        $t = $d;
    }
    return @dates;
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
