class CompanyMailer < ApplicationMailer
  default from: "prizy@btoa-company.com"

  def welcome_email(data)
    @company = data 
    mail(to: @company[:email], subject: "【重要】Prizy登録完了のお知らせ")
  end

  def request_reward_email(data)
    @company = data 
    mail(to: @company[:email], subject: "【Prizy】ポイントの交換が申請されました！")
  end

  def reset_password(data)
    @company = data 
    mail(to: @company[:email], subject: "【Prizy】Reset Password")
  end
end
