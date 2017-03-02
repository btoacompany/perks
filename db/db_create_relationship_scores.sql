CREATE TABLE relationship_scores (
  id	      INT AUTO_INCREMENT NOT NULL,
  user_id     INT NOT NULL,
  scores      json NOT NULL, 
  create_time DATETIME NOT NULL,
  update_time DATETIME NOT NULL,
  delete_flag TINYINT(2) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
