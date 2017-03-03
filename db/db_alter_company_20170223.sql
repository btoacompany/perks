ALTER TABLE company ADD allowed_ips TEXT AFTER user_id;
ALTER TABLE company ADD ip_limit_flag TINYINT(2) DEFAULT 0 AFTER user_id;
ALTER TABLE company ADD fixed_point INT AFTER user_id;
ALTER TABLE company ADD point_fixed_flag TINYINT(2) DEFAULT 0 AFTER user_id;
ALTER TABLE company ADD invite_email_flag TINYINT(2) DEFAULT 0 AFTER user_id;
