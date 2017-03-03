CREATE TABLE departments(
  id		INT AUTO_INCREMENT NOT NULL,
  dep_name	VARCHAR(191) NOT NULL,
  company_id	INT NOT NULL,
  create_time	DATETIME NOT NULL,
  update_time	DATETIME NOT NULL,
  delete_flag	TINYINT(2) DEFAULT 0,
  PRIMARY KEY (id)
);
