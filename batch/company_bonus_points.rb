company = Company.where(delete_flag: 0, bonus_points: 0)

company.each do | c|
  puts "--- COMPANY #{c.id} - #{c.name} ---"
  c[:bonus_points] = 3000 
  c.save

  puts " ### DONE ###"
  sleep(1)
end
