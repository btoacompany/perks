@user = User.find(1)
data = {
  email: @user.email
}

TestMailer.test_mail(data).deliver_now
