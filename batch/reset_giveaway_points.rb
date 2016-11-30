users = User.where(delete_flag: 0)

users.each do | user |
  user[:out_points] = 150
  if user[:company_id] == 26
    user[:out_points] = 3000 
    
  end
  user.save

  sleep(1)
end
