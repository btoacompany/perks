CREATE TABLE comments (
  id		INT AUTO_INCREMENT NOT NULL,
  company_id	INT NOT NULL,
  user_id	INT NOT NULL,
  post_id	INT NOT NULL,
  comments	TEXT,
  create_time	DATETIME NOT NULL,
  update_time	DATETIME NOT NULL,
  delete_flag	TINYINT(2) DEFAULT 0,
  PRIMARY KEY (id)
);
