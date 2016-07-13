CREATE TABLE request_rewards (
  id		INT AUTO_INCREMENT NOT NULL,
  company_id	INT NOT NULL,
  user_id	INT NOT NULL,
  reward_id	INT NOT NULL,
  status	TINYINT(2) DEFAULT 0,
  create_time	DATETIME NOT NULL,
  update_time	DATETIME NOT NULL,
  delete_flag	TINYINT(2) DEFAULT 0,
  PRIMARY KEY (id)
);
