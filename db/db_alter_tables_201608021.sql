ALTER TABLE users ADD COLUMN deliver_invite_mail TINYINT(2) DEFAULT 0 NOT NULL AFTER plan;
ALTER TABLE users ADD COLUMN send_post_mail TINYINT(2) DEFAULT 0 NOT NULL AFTER plan;
ALTER TABLE users ADD COLUMN send_approved TINYINT(2) DEFAULT 0 NOT NULL AFTER plan;
ALTER TABLE posts ADD COLUMN deliver_post_mail TINYINT(2) DEFAULT 0 NOT NULL AFTER description;
ALTER TABLE request_rewards ADD COLUMN deliver_approve_mail TINYINT(2) DEFAULT 0 NOT NULL
AFTER status;
ALTER TABLE request_rewards ADD COLUMN deliver_request_mail TINYINT(2) DEFAULT 0 NOT NULL
AFTER status;
