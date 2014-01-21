create database imot;

CREATE TABLE `user` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `uid` int(11) NOT NULL DEFAULT '0' COMMENT '用户id',
      `username` varchar(50) NOT NULL DEFAULT '' COMMENT '用户名',
      `realname` varchar(50) NOT NULL DEFAULT '',
      `login_time` timestamp NULL DEFAULT NULL,
      `login_ip` varchar(50) DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `uid` (`uid`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

CREATE TABLE `dbmo_server` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `server` varchar(125) NOT NULL,
    `port` varchar(25) NOT NULL,
    `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

alter table dbmo_server add `db_user` varchar(50) NOT NULL;
alter table dbmo_server add `db_passwd` varchar(50) NOT NULL;
alter table dbmo_server change db_passwd db_passwd varchar(50) NOT NULL DEFAULT '';

CREATE TABLE `dbmo_value` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `sid` int(11) NOT NULL DEFAULT '0',
    `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `v_type` varchar(50) NOT NULL,
    `value` varchar(50) NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`),
    KEY `searchsid` (`sid`,`v_type`,`create_time`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
