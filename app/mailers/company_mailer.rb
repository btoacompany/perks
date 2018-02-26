class CompanyMailer < ActionMailer::Base
  default from: "support.prizy@btoa-company.com"

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

  def release_article(email, subject, description)
    @subject = subject
    @description = description
    mail(to: email, subject: @subject)
  end

  def deliver_contact_mail(email, subject, description)
    @subject = subject
    @description = description
    mail(to: email, subject: @subject)
  end

  def recommend_mail(email, subject)
    mail(to: data[:email], subject: "【Prizy】今週の勝手にレコメンド")
  end
end

