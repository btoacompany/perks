company_ids = [1]
company_ids.each do |company_id|
  users = User.of_company(company_id).available
  teams = Team.of_company(company_id).available

  users.each 
end


users.each do |user|
  # targets = [{user1: nil, team: nil}, {user2: nil, team: nil}]
  targets = Array.new
  selected_user_ids = Array.new
  # 
  tags = Article.joins(:tag).pluck(:user_id)
  target_users = users.where.not(id: user.id).sample(2)
  teams.map { |team| targets.push({user: user, team: team}) if team.member_ids.include?(user.id) }
  

  data = {
    email: user.email,
    target: targets
  }
  CompanyMailer.recommend_mail(data).deliver_now
  sleep(0.5)
end
