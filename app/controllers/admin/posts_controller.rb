class Admin::PostsController < Admin::Base
  require 'csv'
  require 'nkf'

  def index
    @posts = Post.where(company_id: @company.id, delete_flag: 0).order(create_time: :desc).paginate(page: params[:page], per_page: 40)
    @teams = Team.where(company_id: @company.id)
  end

  def export_all_posts
    if params[:period] == "three_month"
      period = Date.today - 3.months
    elsif params[:period] == "six_month"
      period = Date.today - 6.months
    elsif params[:period] == "twelve_month"
      period = Date.today - 12.months
    end
    @posts = Post.where(company_id: @company.id, delete_flag: 0).where('create_time >= ?', period)
    teams = Team.where(company_id: @company.id)

    headers = %w(日時 所属 送信者 所属 受信者 内容)
    csv_str = CSV.generate do |csv|
      csv << headers
      @posts.all.each do |post|
        if post.receiver_id.present? && post.receiver_id.include?(",") && post.receiver_id.split(",").count > 0
          post.receiver_id.split(",").each do |receiver_id|
            user_assigned_team = ""
            receiver_assigned_team = ""
            receiver_name = ""


            teams.each do |t|
              if t.member_ids.present? && t.member_ids.include?(post.user.id.to_s)
                user_assigned_team = "#{t.department.try(:dep_name)} #{t.try(:team_name)}"
                break
              end
              user_assigned_team = "所属がありません" unless user_assigned_team.present?
              if t.member_ids.present? && t.member_ids.include?(post.receiver_id)
                receiver_assigned_team = "#{t.department.try(:dep_name)} #{t.try(:team_name)}"
                user = User.find_by(id: receiver_id.to_i)
                receiver_name = "#{user.try(:lastname)}" "#{user.try(:lastname)}"
              end
            end
            csv << [post.create_time.strftime("%Y/%m/%d %H:%M:%S"), user_assigned_team, "#{post.user.try(:lastname)} #{post.user.try(:lastname)}", receiver_assigned_team, receiver_name, post.description]
          end
        else
          user_assigned_team = ""
          receiver_assigned_team = ""
          teams.each do |t|
            if t.member_ids.present? && t.member_ids.include?(post.user.id.to_s)
              user_assigned_team = "#{t.department.try(:dep_name)} #{t.try(:team_name)}"
              break
            end
            user_assigned_team = "所属がありません" unless user_assigned_team.present?
            if t.member_ids.present? && t.member_ids.include?(post.receiver_id.to_s)
              receiver_assigned_team = "#{t.department.try(:dep_name)} #{t.try(:team_name)}"
              break
            end
            receiver_assigned_team = "所属がありません" unless receiver_assigned_team.present?
          end
          csv << [post.create_time.strftime("%Y/%m/%d %H:%M:%S"), user_assigned_team, "#{post.user.try(:lastname)}" "#{post.user.try(:lastname)}", receiver_assigned_team, "#{post.receiver.try(:lastname)}" "#{post.receiver.try(:lastname)}", post.description]
        end
      end
    end
    datetime = Time.now
    format_datetime = datetime.strftime('%Y_%m_%d_%H%M')
    send_data csv_str, filename: "#{format_datetime}" + "メッセージ一覧" , type: 'text/csv;'
  end
end
