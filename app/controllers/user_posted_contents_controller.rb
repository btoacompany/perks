class UserPostedContentsController < ApplicationController
  before_action :init

  def init
    if session[:email].present? || cookies[:email].present?
      email = session[:email] || cookies[:email]
      user = User.find_by_email(email)
      unless user.nil?
        if user.admin == 1
          @id = user.company_id
          @user_id = user.id
        end
      else
        redirect_to "/logout"
      end
      @company = Company.find(@id)
    else
      logout
    end
    if Rails.env.production?
      @s3_url = "https://s3-ap-northeast-1.amazonaws.com/prizy"
      @s3_bucket = "prizy"
    elsif Rails.env.development?
      @s3_url = "https://s3-ap-northeast-1.amazonaws.com/btoa-img"
      @s3_bucket = "btoa-img"
    end
  end

  def index
    @user_posted_contents = UserPostedContent.where(company_id: @company.id)
    @teams = Team.where(company_id: @company.id, delete_flag: 0)
    @team_members = Hash.new
    @teams.each do |team|
    	if team.member_ids.present?
    		@team_members.store(team.member_ids.split(","), team.team_name)
    	end
    end
  end

  def create
  	if params[:image].present?
	    src    = params[:image]
	    src_ext    = File.extname(src.original_filename)
	    s3  = Aws::S3::Resource.new
	    obj = s3.bucket(@s3_bucket).object("company/banner_#{@banner_id}_pic#{src_ext}")
	    obj.upload_file src.tempfile, {acl: 'public-read'}
	    image = obj.public_url
	  else
	  	image = nil
	  end
    UserPostedContent.create(
      company_id: @id,
      user_id: @user_id,
      description: params[:description],
      img_src: image
      )
    redirect_to "/profile/articles"
  end
end
