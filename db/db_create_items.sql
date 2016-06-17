CREATE TABLE items (
  id INT AUTO_INCREMENT NOT NULL,
  name VARCHAR(255) NOT NULL,
  img_src VARCHAR(255),
  url VARCHAR(255),
  category_id INT NOT NULL,
  description TEXT,
  supplier_id INT NOT NULL,
  supplier_name VARCHAR(255) NOT NULL,
  price INT NOT NULL DEFAULT 0,
  discount INT DEFAULT 0,
  sale_price INT DEFAULT 0,
  status TINYINT(2) NOT NULL DEFAULT 0,
  create_time DATETIME NOT NULL,
  update_time DATETIME NOT NULL,
  delete_flag TINYINT(2) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
