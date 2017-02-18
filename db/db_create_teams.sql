CREATE TABLE teams(
  id		INT AUTO_INCREMENT NOT NULL,
  department_id	INT NOT NULL,
  team_name	VARCHAR(191) NOT NULL,
  company_id	INT NOT NULL,
  manager_id	INT NOT NULL,
  member_ids	VARCHAR(191) NOT NULL,
  create_time	DATETIME NOT NULL,
  update_time	DATETIME NOT NULL,
  delete_flag	TINYINT(2) DEFAULT 0,
  PRIMARY KEY (id)
);
