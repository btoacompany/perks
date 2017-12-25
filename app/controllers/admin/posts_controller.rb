class Admin::PostsController < Admin::Base
  require 'csv'

  def index
    @posts = Post.where(company_id: @company.id, delete_flag: 0).order(create_time: :desc).paginate(page: params[:page], per_page: 40)
    @teams = Team.where(company_id: @company.id)
    # @teams = Team.teams(@company.id)
  end

  def export_all_posts
    @posts = Post.where(company_id: @company.id, delete_flag: 0)
    respond_to do |format|
      format.html
      format.csv { send_data @posts.to_csv }
    end

    # headers = %w(日時 送信者 受信者 内容)
    # data = CSV.generate(encoding: Encoding::SJIS, headers: headers ) do |csv|
    #   csv << headers
    #   @posts.each do |post|
    #     csv << [post.create_time.strftime("%Y/%m/%d %H:%M:%S"), post.user.fullname, post.receiver.fullname, post.description]
    #   end
    # end
    # datetime = Time.now
    # format_datetime = datetime.strftime('%Y_%m_%d_%H%M')
    # send_data(data , filename:  "#{format_datetime}" + "社員登録フォーマット" + '.csv',type: 'csv')
  end
end
