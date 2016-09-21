users = User.select("id, name, company_id").group("name").having("count(name) > 1").order("company_id")

users.each do | user |
  results = User.select("id, name, company_id").where("name LIKE '#{user.name}'").where(company_id: user.company_id)

  results.each_with_index do | result, i | 
    result.name += (i+1).to_s 
    result.save
  end
end
