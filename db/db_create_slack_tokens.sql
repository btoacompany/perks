CREATE TABLE slack_tokens(
  token VARCHAR(191) NOT NULL,
  team_id VARCHAR(191) NOT NULL,
  webhooks_url VARCHAR(191),
  bot_token VARCHAR(191),
  PRIMARY KEY (token)
);
