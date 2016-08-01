class UserMailer < ApplicationMailer
  default from: "info@btoa-company.com"

  def verify_account(data)
    @user = data 
    mail(to: @user[:email], subject: "【Prizy】#{@user[:company_owner]}さんから招待が届きました。")
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
