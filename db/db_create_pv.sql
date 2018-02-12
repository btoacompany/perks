CREATE TABLE pv (
  id			INT AUTO_INCREMENT NOT NULL,
  company_id	INT NOT NULL,
  user_id		INT NOT NULL,
  team_id		INT NOT NULL DEFAULT 0,
  page_path		VARCHAR(255),
  pv_count		INT NOT NULL DEFAULT 0,
  track_date	DATE NOT NULL,
  create_time	DATETIME NOT NULL,
  PRIMARY KEY (id)
);
