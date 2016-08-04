CREATE TABLE posts (
  id		INT AUTO_INCREMENT NOT NULL,
  company_id	INT NOT NULL,
  user_id	INT(11) NOT NULL,
  receiver_id	INT(11) NOT NULL,
  points	INT DEFAULT 0,
  description	VARCHAR(191),
  create_time	DATETIME NOT NULL,
  update_time	DATETIME NOT NULL,
  delete_flag	TINYINT(2) DEFAULT 0,
  PRIMARY KEY (id)
);
