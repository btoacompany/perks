CREATE TABLE vendors (
  id	      INT AUTO_INCREMENT NOT NULL,
  name	      VARCHAR(255) NOT NULL,
  owner	      VARCHAR(255),
  email	      VARCHAR(255) UNIQUE,
  address     VARCHAR(255),
  phone	      VARCHAR(255),
  url	      VARCHAR(255),
  plan	      TINYINT(2) DEFAULT 0,
  password    VARCHAR(255),
  salt	      VARCHAR(255),
  create_time DATETIME NOT NULL,
  update_time DATETIME NOT NULL,
  delete_flag TINYINT(2) DEFAULT 0,
  PRIMARY KEY (id)
);
