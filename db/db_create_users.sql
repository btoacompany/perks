CREATE TABLE users (
  id		INT AUTO_INCREMENT NOT NULL,
  name		VARCHAR(255),
  firstname	VARCHAR(255),
  lastname	VARCHAR(255),
  email		VARCHAR(255) NOT NULL UNIQUE,
  birthday	DATE, 
  gender	TINYINT(2) NOT NULL DEFAULT 0,
  img_src	VARCHAR(255),
  job_title	VARCHAR(255),
  company_id	INT(11) NOT NULL,
  in_points	INT(11) NOT NULL DEFAULT 0,
  out_points	INT(11) NOT NULL DEFAULT 0,
  kudos		INT(11) NOT NULL DEFAULT 0,
  plan		TINYINT(2) NOT NULL DEFAULT 0,
  verified	TINYINT(2) NOT NULL DEFAULT 0,
  password	VARCHAR(255),
  salt		VARCHAR(255),
  create_time	DATETIME NOT NULL,
  update_time	DATETIME NOT NULL,
  delete_flag	TINYINT(2) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
