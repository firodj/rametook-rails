CREATE TABLE `addressbook_contacts` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `email` varchar(255) default NULL,
  `description` text,
  `address` varchar(255) default NULL,
  `city` varchar(255) default NULL,
  `country` varchar(255) default NULL,
  `birthday` date default NULL,
  `department_id` int(255) default NULL,
  `image` varchar(255) default NULL,
  `user_id` int(11) default NULL,
  `public` tinyint(1) default '0',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=96 DEFAULT CHARSET=latin1;

CREATE TABLE `addressbook_group_phones` (
  `id` int(11) NOT NULL auto_increment,
  `addressbook_group_id` int(255) default NULL,
  `addressbook_contact_id` int(255) default NULL,
  `addressbook_phone_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=274 DEFAULT CHARSET=latin1;

CREATE TABLE `addressbook_groups` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `user_id` int(255) default NULL,
  `public` tinyint(1) default NULL,
  `department_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

CREATE TABLE `addressbook_phones` (
  `id` int(11) NOT NULL auto_increment,
  `addressbook_contact_id` int(11) default NULL,
  `name` varchar(255) default NULL,
  `number` varchar(255) default NULL,
  `display_number` varchar(255) default NULL,
  `position` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=51 DEFAULT CHARSET=latin1;

CREATE TABLE `departments` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `parent_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=latin1;

CREATE TABLE `languages` (
  `id` int(11) NOT NULL auto_increment,
  `plugins` varchar(255) default NULL,
  `name` varchar(255) default NULL,
  `value` varchar(255) default NULL,
  `language` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=124 DEFAULT CHARSET=latin1;

CREATE TABLE `modem_at_commands` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(16) default NULL,
  `function_name` varchar(255) default NULL,
  `at_type` varchar(16) default NULL,
  `case_format` varchar(255) default NULL,
  `format` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=latin1;

CREATE TABLE `modem_at_commands_modem_types` (
  `modem_at_command_id` int(11) NOT NULL,
  `modem_type_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `modem_devices` (
  `id` int(11) NOT NULL auto_increment,
  `device` varchar(255) default NULL,
  `baudrate` int(11) default NULL,
  `databits` int(11) default NULL,
  `stopbits` int(11) default NULL,
  `parity` int(11) default NULL,
  `active` int(11) default NULL,
  `identifier` varchar(255) default NULL,
  `modem_type_id` int(11) default NULL,
  `signal_quality` int(11) default NULL,
  `last_refresh` datetime default NULL,
  `capabilities` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;

CREATE TABLE `modem_error_messages` (
  `id` int(11) NOT NULL auto_increment,
  `err_type` varchar(255) default NULL,
  `code` int(11) default NULL,
  `function_name` varchar(255) default NULL,
  `message` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `err_type` (`err_type`,`code`)
) ENGINE=InnoDB AUTO_INCREMENT=103 DEFAULT CHARSET=latin1;

CREATE TABLE `modem_pdu_logs` (
  `id` int(11) NOT NULL auto_increment,
  `modem_short_message_id` int(11) default NULL,
  `length_pdu` int(11) default NULL,
  `pdu` text,
  `first_octet` varchar(255) default NULL,
  `data_coding` varchar(255) default NULL,
  `udh` text,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `modem_short_messages` (
  `id` int(11) NOT NULL auto_increment,
  `modem_device_id` int(11) default NULL,
  `status` varchar(255) collate utf8_unicode_ci default NULL,
  `message_ref` int(11) default NULL,
  `number` varchar(255) collate utf8_unicode_ci default NULL,
  `message` varchar(255) collate utf8_unicode_ci default NULL,
  `check_time` datetime default NULL,
  `discharge_time` datetime default NULL,
  `service_center_time` datetime default NULL,
  `waiting_time` datetime default NULL,
  `callback_number` varchar(255) collate utf8_unicode_ci default NULL,
  `priority` int(11) default NULL,
  `privacy` int(11) default NULL,
  `trial` int(11) default NULL,
  `sms_inbox_id` int(11) default NULL,
  `sms_outbox_recipient_id` int(11) default NULL,
  `cancel_sending` tinyint(1) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `modem_types` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `sms_mode` varchar(255) default NULL,
  `init_command` varchar(255) default NULL,
  `detect_pattern` varchar(255) default NULL,
  `detect_regexp` varchar(255) default NULL,
  `identifier_exact` text,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=latin1;

CREATE TABLE `roles` (
  `id` int(11) NOT NULL auto_increment,
  `title` varchar(255) default NULL,
  `description` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;

CREATE TABLE `roles_users` (
  `role_id` int(11) default NULL,
  `user_id` int(11) default NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `schema_info` (
  `version` int(11) default NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `settings` (
  `id` int(11) NOT NULL auto_increment,
  `plugins` varchar(255) default NULL,
  `name` varchar(255) default NULL,
  `value` varchar(255) default NULL,
  `description` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;

CREATE TABLE `sms_inbox_filters` (
  `id` int(11) NOT NULL auto_increment,
  `addressbook_contact_id` int(11) default NULL,
  `department_id` int(11) default NULL,
  `user_group_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

CREATE TABLE `sms_inboxes` (
  `id` int(11) NOT NULL auto_increment,
  `number` varchar(255) default NULL,
  `message` varchar(255) default NULL,
  `sent_time` datetime default NULL,
  `received_time` datetime default NULL,
  `has_read` tinyint(1) default NULL,
  `user_group_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  `removed` tinyint(1) default NULL,
  `removed_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;

CREATE TABLE `sms_keywords` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `function` varchar(255) default NULL,
  `is_keyword` int(1) default NULL,
  `help_info` text,
  `active_since` datetime default NULL,
  `active_until` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

CREATE TABLE `sms_logs` (
  `id` int(11) NOT NULL auto_increment,
  `status` varchar(255) default NULL,
  `service_center_time` datetime default NULL,
  `number` varchar(255) default NULL,
  `message` varchar(255) default NULL,
  `process` text,
  `check_time` datetime default NULL,
  `short_message_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `sms_outbox_recipients` (
  `id` int(11) NOT NULL auto_increment,
  `number` varchar(255) default NULL,
  `sent_time` datetime default NULL,
  `sms_outbox_id` int(11) default NULL,
  `removed` tinyint(1) default NULL,
  `removed_at` datetime default NULL,
  `status` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=latin1;

CREATE TABLE `sms_outboxes` (
  `id` int(11) NOT NULL auto_increment,
  `message` varchar(255) default NULL,
  `created_by_user_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `status` varchar(255) default NULL,
  `removed` tinyint(1) default NULL,
  `status_invalid` tinyint(1) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;

CREATE TABLE `sms_replies` (
  `id` int(11) NOT NULL auto_increment,
  `function` varchar(255) default NULL,
  `action` varchar(255) default NULL,
  `message` varchar(255) default NULL,
  `tags` varchar(255) default NULL,
  `help_info` text,
  `active` tinyint(1) default '1',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

CREATE TABLE `sms_templates` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `template` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;

CREATE TABLE `users` (
  `id` int(11) NOT NULL auto_increment,
  `login` varchar(255) default NULL,
  `email` varchar(255) default NULL,
  `crypted_password` varchar(40) default NULL,
  `salt` varchar(40) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `last_login_at` datetime default NULL,
  `last_ip` varchar(255) default NULL,
  `activation_code` varchar(40) default NULL,
  `activated_at` datetime default NULL,
  `remember_token` varchar(255) default NULL,
  `remember_token_expires_at` datetime default NULL,
  `department_id` int(11) default NULL,
  `first_name` varchar(100) default NULL,
  `last_name` varchar(100) default NULL,
  `birthday` date default NULL,
  `bio` varchar(255) default NULL,
  `website` varchar(255) default NULL,
  `address` varchar(255) default NULL,
  `city` varchar(255) default NULL,
  `country` varchar(255) default NULL,
  `userimage` varchar(255) default 'admin.gif',
  `addressbook_contact_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

INSERT INTO schema_info (version) VALUES (9)