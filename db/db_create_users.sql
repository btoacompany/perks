CREATE TABLE users (
  id		INT AUTO_INCREMENT NOT NULL,
  name		VARCHAR(191),
  firstname	VARCHAR(191),
  lastname	VARCHAR(191),
  email		VARCHAR(191) NOT NULL UNIQUE,
  birthday	DATE, 
  gender	TINYINT(2) NOT NULL DEFAULT 0,
  img_src	VARCHAR(191),
  job_title	VARCHAR(191),
  company_id	INT(11) NOT NULL,
  in_points	INT(11) NOT NULL DEFAULT 0,
  out_points	INT(11) NOT NULL DEFAULT 0,
  kudos		INT(11) NOT NULL DEFAULT 0,
  plan		TINYINT(2) NOT NULL DEFAULT 0,
  verified	TINYINT(2) NOT NULL DEFAULT 0,
  password	VARCHAR(191),
  salt		VARCHAR(191),
  create_time	DATETIME NOT NULL,
  update_time	DATETIME NOT NULL,
  delete_flag	TINYINT(2) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
