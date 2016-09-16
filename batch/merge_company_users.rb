if Rails.env.production?
  prizy_url = "http://prizy.me"
  s3_bucket = "prizy"
elsif Rails.env.development?
  prizy_url = "http://localhost:3000"
  s3_bucket = "btoa-img"
end

company = Company.where(delete_flag: 0)

company.each do | c |
  user_exist = User.find_by_email(c.email)

  p "-- company_#{c.id}: #{c.email} --"

  if user_exist.nil?
    p "new company user"
    user = User.new
    user.email	    = c.email
    user.password   = c.password
    user.salt	    = c.salt
    user.img_src    = "https://#{s3_bucket}.s3-ap-northeast-1.amazonaws.com/common/noimg_pc.png"
    user.name	    = (c.email).split("@")[0]
    user.company_id = c.id
    user.out_points = 150
    user.admin	    = 1
    user.verified   = 0
    user.deliver_invite_mail = 3
    user.save
  else
    p "existing company user"
    user_exist.admin	= 1
    user_exist.deliver_invite_mail = 3
    user_exist.verified   = 1
    user_exist.save
  end

  sleep(1)
end
