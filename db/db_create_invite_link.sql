CREATE TABLE invite_link (
  id		INT AUTO_INCREMENT NOT NULL,
  company_id	INT NOT NULL,
  c_code	VARCHAR(255) NOT NULL,
  create_time	DATETIME NOT NULL,
  update_time	DATETIME NOT NULL,
  delete_flag	TINYINT(2) DEFAULT 0,
  PRIMARY KEY (id)
);
