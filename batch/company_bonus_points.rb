company = Company.where(delete_flag: 0)

company.each do | c|
  c[:bonus_points] = 3000 
  c.save

  sleep(1)
end
