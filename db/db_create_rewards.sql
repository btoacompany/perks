CREATE TABLE rewards (
  id	      INT AUTO_INCREMENT NOT NULL,
  title	      VARCHAR(255) NOT NULL,
  company_id  INT NOT NULL,
  company_name VARCHAR(255) NOT NULL,
  img_src     VARCHAR(255),
  url	      VARCHAR(255),
  category_id INT DEFAULT 0,
  description TEXT,
  points      INT DEFAULT 0,
  create_time DATETIME NOT NULL,
  update_time DATETIME NOT NULL,
  delete_flag TINYINT(2) DEFAULT 0,
  PRIMARY KEY (id)
);
