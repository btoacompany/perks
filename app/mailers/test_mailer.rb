class TestMailer < ApplicationMailer
  def test_mail(data)
    @user = data 
    mail(to: @user[:email], subject: "【Prizy】これはテストです")
  end
end
