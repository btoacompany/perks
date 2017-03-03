CREATE TABLE condition_scores (
  id		      INT AUTO_INCREMENT NOT NULL,
  team_id	      INT NOT NULL,
  user_id	      INT NOT NULL,
  boss_relation	      FLOAT(4,2) NOT NULL DEFAULT 0, 
  colleague_relation  FLOAT(4,2) NOT NULL DEFAULT 0, 
  work_meaning	      FLOAT(4,2) NOT NULL DEFAULT 0,
  work_environment    FLOAT(4,2) NOT NULL DEFAULT 0, 
  growth_score	      FLOAT(4,2) NOT NULL DEFAULT 0, 
  stress_score	      FLOAT(4,2) NOT NULL DEFAULT 0, 
  total_score	      FLOAT(4,2) NOT NULL DEFAULT 0, 
  create_time	      DATETIME NOT NULL,
  update_time	      DATETIME NOT NULL,
  delete_flag	      TINYINT(2) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);
