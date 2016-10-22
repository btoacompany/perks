ALTER TABLE request_rewards ADD COLUMN reward_prizy_id INT DEFAULT 0 AFTER reward_id;
ALTER TABLE request_rewards CHANGE reward_id reward_id INT DEFAULT 0 AFTER user_id;
ALTER TABLE company ADD COLUMN plan_start_date datetime AFTER plan_approved;
