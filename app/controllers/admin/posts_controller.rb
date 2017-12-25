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

    headers = %w(日時 送信者 受信者 内容)
    csv_str = CSV.generate do |csv|
      csv << headers
        @posts.all.each do |post|
        csv << [post.create_time.strftime("%Y/%m/%d %H:%M:%S"), post.user.fullname, post.receiver.fullname, post.description]
      end
    end
    datetime = Time.now
    format_datetime = datetime.strftime('%Y_%m_%d_%H%M')
    send_data csv_str, filename: "#{format_datetime}" + "メッセージ一覧" , type: 'text/csv;'
  end
end
