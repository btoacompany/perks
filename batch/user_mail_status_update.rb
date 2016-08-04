users = User.where(verified: 1, deliver_invite_mail: 0, delete_flag: 0)

users.each do | user |
  begin
    user.deliver_invite_mail = 3
    user.save
  rescue Exception => e
    puts "#---- ERROR ----#"
    puts e.message
  end
end
