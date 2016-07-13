CREATE TABLE admins (
  id	      INT AUTO_INCREMENT NOT NULL,
  name	      VARCHAR(255) NOT NULL UNIQUE,
  firstname   VARCHAR(255) NOT NULL,
  lastname    VARCHAR(255) NOT NULL,
  email	      VARCHAR(255) NOT NULL UNIQUE,
  gender      TINYINT(2) NOT NULL DEFAULT 0,
  admin_type  TINYINT(2) NOT NULL DEFAULT 0,
  password    VARCHAR(255),
  salt	      VARCHAR(255),
  create_time DATETIME NOT NULL,
  update_time DATETIME NOT NULL,
  delete_flag TINYINT(2) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
