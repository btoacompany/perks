ALTER TABLE users ADD manager_flag TINYINT(2) DEFAULT 0 AFTER admin;
ALTER TABLE users ADD member_flag TINYINT(2) DEFAULT 0 AFTER admin;
