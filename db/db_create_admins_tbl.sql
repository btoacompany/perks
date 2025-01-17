CREATE TABLE admins (
  id INT AUTO_INCREMENT NOT NULL,
  name VARCHAR(191) NOT NULL,
  firstname VARCHAR(191),
  lastname VARCHAR(191),
  email VARCHAR(191) NOT NULL UNIQUE,
  gender TINYINT(2) DEFAULT 0,
  admin_type TINYINT(2) DEFAULT 0,
  password VARCHAR(191) NOT NULL,
  salt VARCHAR(191) NOT NULL,
  create_time DATETIME NOT NULL,
  update_time DATETIME NOT NULL,
  delete_flag TINYINT(2) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
