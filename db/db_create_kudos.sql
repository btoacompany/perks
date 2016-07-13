CREATE TABLE kudos (
  id		INT AUTO_INCREMENT NOT NULL,
  post_id	INT NOT NULL,
  user_id	INT NOT NULL,
  kudos		TINYINT(2) DEFAULT 0,
  create_time	DATETIME NOT NULL,
  update_time	DATETIME NOT NULL,
  delete_flag	TINYINT(2) DEFAULT 0,
  PRIMARY KEY (id)
);
