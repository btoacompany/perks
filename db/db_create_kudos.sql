CREATE TABLE user_kudos (
  id		INT AUTO_INCREMENT NOT NULL,
  company_id	INT NOT NULL,
  company_name	VARCHAR(255) NOT NULL,
  giver_id	INT(11) NOT NULL,
  giver_name	VARCHAR(255) NOT NULL,
  receiver_id	INT(11) NOT NULL,
  receiver_name	VARCHAR(255) NOT NULL,
  kudos		INT DEFAULT 0,
  create_time	DATETIME NOT NULL,
  update_time	DATETIME NOT NULL,
  delete_flag	TINYINT(2) DEFAULT 0,
  PRIMARY KEY (id)
);
