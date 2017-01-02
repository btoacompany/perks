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

  def reset_password(data)
    @user = data 
    mail(to: @user[:email], subject: "【Prizy】パスワードの再設定")
  end

  def invite_welcome_email(data)
    @user = data 
    mail(to: @user[:email], subject: "【Prizy】ご登録ありがとうございます")
  end

  def redeem_prizy_reward (data)
    @user = data
    mail(to: "info@btoa-company.com", subject: "【Prizy】Redeem Reward")
  end
end
