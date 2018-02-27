users = User.of_company(1).available
teams = Team.of_company(1).available


users.each do |user|
  belonging = nil
  teams.map { |team| belonging = team if team.member_ids.present? && team.member_ids.split(",").include?(user.id.to_s) }
  member_ids = belonging.member_ids.split(",") - user.id
  two_targets_from_team = member_ids.sample(2)
  target_from_article = Tag.of_company(user.company_id).where.not(user_id: user.id).where.not(user_id: two_targets_from_team).pluck(:user_id).sample(1)
  
  # targets = [{user1: nil, team: nil}, {user2: nil, team: nil}]
  # targets = {team: user, tea}
  targets = Hash.new
  target_users = two_targets_from_team + target_from_article
  target_users = User.available.of_company(user_id).where(id: target_users)
  target_users.each do |user|
    belonging = nil
    teams.map { |team| belonging = team if team.member_ids.present? && team.member_ids.split(",").include?(user.id.to_s) }
    targets.store(belonging, user)
  end


  data = {
    user: user,
    target: targets
  }
  # CompanyMailer.recommend_mail(data).deliver_now
  sleep(0.5)
end
