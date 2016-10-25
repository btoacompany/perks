ALTER TABLE request_rewards ADD COLUMN reward_prizy_id INT DEFAULT 0 AFTER reward_id;
ALTER TABLE request_rewards CHANGE reward_id reward_id INT DEFAULT 0 AFTER user_id;
ALTER TABLE company ADD COLUMN plan_start_date datetime AFTER plan_approved;
ALTER TABLE company ADD COLUMN bonus_default INT DEFAULT 0 AFTER bonus_points;
ALTER TABLE company ADD COLUMN points_default INT DEFAULT 0 AFTER hashtags;
