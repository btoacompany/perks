CREATE TABLE team_scores (
  id		    INT AUTO_INCREMENT NOT NULL,
  team_id	    INT NOT NULL,
  manager_id	    INT NOT NULL,
  team_score	    FLOAT(4,2) NOT NULL DEFAULT 0,
  management_score  FLOAT(4,2) NOT NULL DEFAULT 0, 
  create_time	    DATETIME NOT NULL,
  update_time	    DATETIME NOT NULL,
  delete_flag	    TINYINT(2) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
