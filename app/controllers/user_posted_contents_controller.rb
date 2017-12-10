class UserPostedContentsController < ApplicationController
  before_action :init
  before_filter :init_url, :authenticate_user

  def init
    if session[:id].present? || cookies[:id].present?
      @id = session[:id] || cookies[:id]
      user = User.find(@id)
      @user_id = user.id
      @company = Company.find(user.company_id)
    else
      logout
    end
  end

  def index
    @user_posted_contents = UserPostedContent.where(company_id: @company.id).order(updated_at: :desc)
    @teams = Team.where(company_id: @company.id, delete_flag: 0)
    @team_members = Hash.new
    @teams.each do |team|
    	if team.member_ids.present?
    		@team_members.store(team.member_ids.split(","), team)
    	end
    end
  end

  def create
  	if params[:image].present?
      @last_user_content = UserPostedContent.last
	    src    = params[:image]
	    src_ext    = File.extname(src.original_filename)
	    s3  = Aws::S3::Resource.new
	    obj = s3 .bucket(@s3_bucket).object("company/user_content_#{@last_user_content.id + 1}_pic#{src_ext}")
	    obj.upload_file src.tempfile, {acl: 'public-read'}
	    image = obj.public_url
	  else
	  	image = nil
	  end
    @created_post = UserPostedContent.create(
      company_id: @company.id,
      user_id: @user_id,
      description: params[:description],
      img_src: image
      )
    if @created_post.errors.full_messages.count == 0
      flash[:notice] = "送信が完了しました。"
    else
      flash[:notice] = "送信に失敗しました。"      
    end
    redirect_to "/profile/articles"
  end
end
