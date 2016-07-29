class UserMailer < ApplicationMailer
  default from: "info@btoa-company.com"

  def verify_account(data)
    @user = data 
    mail(to: @user[:email], subject: "【Prizy】Verify your account")
  end

  def reward_approved_email(data)
    @user = data 
    mail(to: @user[:email], subject: "【Prizy】ポイントの交換が承認されました！")
  end

  def receive_points_email(data)
    @user = data 
    mail(to: @user[:email], subject: "【Prizy】#{@user[:giver]}さんより#{@user[:points]}pointのボーナスが届きました")
  end
end
