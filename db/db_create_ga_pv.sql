CREATE TABLE ga_pv (
  id			INT AUTO_INCREMENT NOT NULL,
  company_id	INT NOT NULL,
  page_url		VARCHAR(255),
  page_view		INT NOT NULL DEFAULT 0,
  create_time	DATETIME NOT NULL,
  PRIMARY KEY (id)
);
