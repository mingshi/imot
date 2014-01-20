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
