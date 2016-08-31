if Rails.env.production?
  prizy_url = "http://prizy.me"
elsif Rails.env.development?
  prizy_url = "http://localhost:3000"
end

company = Company.where("invite_link IS NULL")

company.each do | c |
  c_code = (Time.now.to_i).to_s + "_" + (c.id).to_s
  c.invite_link = prizy_url + "/invite?c_code=" + c_code
  c.save

  invite_link = InviteLink.new
  invite_link.save_record({
    :company_id   => c.id,
    :c_code	=> c_code
  })

  sleep(1)
end
