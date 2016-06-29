class UserMailer < ApplicationMailer
  default from: "info@btoa-company.com"

  def verify_account(data)
    @user = data 
    mail(to: @user[:email], subject: "Verify your account")
  end
end
