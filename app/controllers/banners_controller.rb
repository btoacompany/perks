class BannersController < ApplicationController
  before_action :init
  before_filter :init_url

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
  end

  def index
  	@banner = Banner.find_by(company_id: @id, is_deleted: 0)
  end

  def create
    @current_banner = Banner.where(company_id: @id, is_deleted: 0)
    if @current_banner
      @current_banner.update_all(is_deleted: 1)
    end
    @banner_id = Banner.last.id + 1
    src    = params[:banner]
    src_ext    = File.extname(src.original_filename)
    s3  = Aws::S3::Resource.new
    obj = s3.bucket(@s3_bucket).object("company/banner_#{@banner_id}_pic#{src_ext}")
    obj.upload_file src.tempfile, {acl: 'public-read'}
    Banner.create(
      company_id: @id,
      img_src: obj.public_url
      )
    redirect_to company_banners_path
  end
end
