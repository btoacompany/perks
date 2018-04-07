class Admin::PostsController < Admin::Base
  require 'csv'
  require 'nkf'

  def index
    posts = Post.of_company(@company.id).available.order(create_time: :desc)
    teams = Team.of_company(@company.id).available
    users = Hash.new
    User.of_company(@company.id).available.map { |user| users.store(user.id, user) }
    @messages = Array.new
    posts.each do |post|
      post.receiver_id.split(",").each do |id|
        message = Hash.new
        message.store(:date, post.create_time.strftime("%Y%m/%d %H:%M:%S"))
        belonging = nil
        teams.map { |team| belonging = team if team.member_ids.present? && team.member_ids.include?(post.user_id.to_s) }
        message.store(:sender_team, "#{belonging.try(:department).try(:dep_name)}/#{belonging.try(:team_name)}")
        message.store(:sender, post.user.fullname)
        teams.map { |team| belonging = team if team.member_ids.present? && team.member_ids.include?(post.receiver_id) }
        message.store(:receiver_team, "#{belonging.try(:department).try(:dep_name)}/#{belonging.try(:team_name)}")
        receiver = users[id.to_i]
        message.store(:receiver, receiver.try(:fullname))
        message.store(:description, post.description)
        @messages.push(message)
      end
    end
    @messages = Kaminari.paginate_array(@messages).page(params[:page]).per(40)
  end

  def export_all_posts
    if params[:period] == "three_month"
      period = Date.today - 3.months
    elsif params[:period] == "six_month"
      period = Date.today - 6.months
    elsif params[:period] == "twelve_month"
      period = Date.today - 12.months
    end
    posts = Post.of_company(@company.id).available.where('create_time >= ?', period)
    teams = Team.of_company(@company.id).available
    users = Hash.new
    User.of_company(@company.id).available.map { |user| users.store(user.id, user) }

    headers = %w(日時 所属 送信者 所属 受信者 内容)
    csv_str = CSV.generate do |csv|
      csv << headers
      posts.each do |post|
        post.receiver_id.split(",").each do |id|
          sender_belonging = nil
          receiver_belonging = nil
          teams.map { |team| sender_belonging = team if team.member_ids.present? && team.member_ids.include?(post.user_id.to_s) }
          teams.map { |team| receiver_belonging = team if team.member_ids.present? && team.member_ids.include?(post.receiver_id) }
          receiver = users[id.to_i]
          csv << [post.create_time.strftime("%Y/%m/%d %H:%M:%S"), "#{sender_belonging.try(:department).try(:dep_name)}/#{sender_belonging.try(:team_name)}", post.user.fullname, "#{receiver_belonging.try(:department).try(:dep_name)}/#{receiver_belonging.try(:team_name)}", receiver.try(:fullname), post.description]
        end
      end
    end
    datetime = Time.now
    format_datetime = datetime.strftime('%Y_%m_%d_%H%M')
    send_data csv_str, filename: "#{format_datetime}" + "メッセージ一覧" , type: 'text/csv;'
  end
end
