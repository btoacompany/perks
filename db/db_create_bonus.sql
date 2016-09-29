CREATE TABLE bonus (
  id	      INT AUTO_INCREMENT NOT NULL,
  title	      VARCHAR(191) NOT NULL,
  company_id  INT NOT NULL,
  img_src     VARCHAR(191),
  description TEXT,
  points      INT NOT NULL DEFAULT 0,
  create_time DATETIME NOT NULL,
  update_time DATETIME NOT NULL,
  delete_flag TINYINT(2) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
