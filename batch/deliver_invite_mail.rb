# if Rails.env.production?
#   prizy_url = "https://www.prizy.me"
# elsif Rails.env.development?
#   prizy_url = "http://localhost:3000"
# end

# company_ids = Company.where(invite_email_flag: 0).pluck(:id)
# users = User.where(deliver_invite_mail: 0, delete_flag: 0 , company_id: company_ids)
# sum = 0

# users.each do |user|
#   begin
#     if user.email.match(/^.+@.+$/)
#       temp_password = SecureRandom.hex(4)
#       data = {
#         :company_name   => user.company.name,
#         :company_owner  => user.company.owner,
#         :email      => user.email,
#         :password     => temp_password,
#         :name     => user.name,
#         :prizy_url    => prizy_url + "/login",
#         :deliver_invite_mail => 2 #processing
#       }

#       UserMailer.verify_account(data).deliver_now
#       sleep(0.5)
#       user_update = User.find(user.id)
#       user_update.deliver_invite_mail = 3 #delivered
#       user_update.save
#       sum += 1
#     else
#       next
#     end
#   rescue Exception => e
#     puts "#---- ERROR ----#"
#     puts e.message

#     user_update = User.find(user.id)
#     user_update.deliver_invite_mail = 0 #error
#     user_update.save
#   end
# end
