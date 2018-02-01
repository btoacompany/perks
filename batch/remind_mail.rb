users = User.of_company(@company.id)

users.each do |user|
  data = {
    email: user.email
  }
  CompanyMailer.remind_mail(data).deliver_now
  sleep(0.5)
end