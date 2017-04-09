ALTER TABLE company ADD send_point INT(11) NOT NULL DEFAULT 0 AFTER user_id;
ALTER TABLE company ADD receive_point INT(11) NOT NULL DEFAULT 0 AFTER user_id;
ALTER TABLE company ADD change_timeline_image_size INT(11) NOT NULL DEFAULT 0 AFTER user_id;
ALTER TABLE company ADD give_point_to_sender_and_receiver_flag INT(11) NOT NULL DEFAULT 0 AFTER user_id;
ALTER TABLE posts ADD nickname_id INT(11) NOT NULL DEFAULT 0;
