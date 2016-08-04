CREATE TABLE company (
  id	      INT AUTO_INCREMENT NOT NULL,
  name	      VARCHAR(191) NOT NULL,
  owner	      VARCHAR(191) NOT NULL,
  email	      VARCHAR(191) NOT NULL UNIQUE,
  address     VARCHAR(191),
  phone	      VARCHAR(191),
  url	      VARCHAR(191),
  logo	      VARCHAR(191),
  hashtags    VARCHAR(191),
  plan	      TINYINT(2) NOT NULL DEFAULT 0,
  verified    TINYINT(2) NOT NULL DEFAULT 0,
  password    VARCHAR(191),
  salt	      VARCHAR(191),
  create_time DATETIME NOT NULL,
  update_time DATETIME NOT NULL,
  delete_flag TINYINT(2) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
