users = User.where(delete_flag: 0)

users.each do | user |
  company = Company.find(user[:company_id])
  user[:out_points] = company.points_default 

  puts "User: #{user[:company_id]} - #{user[:out_points]}"
  user.save

  sleep(0.1)
end

companies = Company.where(delete_flag: 0)

companies.each do | c |
  c.bonus_points = c.bonus_default
  puts "Company: #{c[:id]} - #{c[:bonus_points]}"
  c.save
  sleep(0.1)
end
