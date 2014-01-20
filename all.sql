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
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8
