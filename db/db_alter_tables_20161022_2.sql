UPDATE rewards SET delete_flag = 1 WHERE img_src LIKE "%img_05%";
UPDATE rewards SET delete_flag = 1 WHERE img_src LIKE "%img_07%";
TRUNCATE request_rewards;
