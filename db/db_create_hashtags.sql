CREATE TABLE hashtags (
  id		INT AUTO_INCREMENT NOT NULL,
  post_id	INT NOT NULL,
  company_id	INT NOT NULL,
  user_id	INT NOT NULL,
  receiver_id	INT NOT NULL,
  hashtag	VARCHAR(255),
  create_time	DATETIME NOT NULL,
  update_time	DATETIME NOT NULL,
  delete_flag	TINYINT(2) DEFAULT 0,
  PRIMARY KEY (id)
);
