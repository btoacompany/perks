users = User.where(delete_flag: 0)

users.each do | user |
  #company = Company.find(user[:company_id])
  if user[:company_id].to_i == 26
    user[:out_points] = 3000
    puts "User: #{user[:company_id]} - #{user[:out_points]}"
    user.save
  end

  sleep(0.1)
end
