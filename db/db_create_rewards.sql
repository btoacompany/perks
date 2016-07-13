CREATE TABLE rewards (
  id	      INT AUTO_INCREMENT NOT NULL,
  title	      VARCHAR(255) NOT NULL,
  company_id  INT NOT NULL,
  img_src     VARCHAR(255),
  url	      VARCHAR(255),
  category_id INT NOT NULL DEFAULT 0,
  description TEXT,
  points      INT NOT NULL DEFAULT 0,
  plan	      TINYINT(2) NOT NULL DEFAULT 0,
  create_time DATETIME NOT NULL,
  update_time DATETIME NOT NULL,
  delete_flag TINYINT(2) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
