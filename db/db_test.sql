CREATE TABLE tests (
  id INT AUTO_INCREMENT NOT NULL,
  name	VARCHAR(255),
  email VARCHAR(255),
  accounts JSON,
  create_time DATETIME NOT NULL,
  update_time DATETIME NOT NULL,
  delete_flag TINYINT(2) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
