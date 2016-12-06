users = User.where(delete_flag: 0, company_id: 26)

users.each do | user |
  puts "User: #{user[:id]} - #{user[:in_points]}"
  user.in_points *= 20
  puts "User: #{user[:id]} - #{user[:in_points]}"
  puts "------"
  user.save
  sleep(0.1)
end
