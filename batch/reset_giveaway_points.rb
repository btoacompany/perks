users = User.where(delete_flag: 0)

users.each do | user |
  user[:out_points] = 150
  user.save

  sleep(1)
end
