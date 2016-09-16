#coding:utf-8
require 'util.rb'
require 'uri'
require 'net/http'

class UsersController < ApplicationController
  before_filter :init, :authenticate_user, :except => [:login, :login_complete, :logout,
  :invite, :invite_complete, :forgot_password, :forgot_password_submit, :fb_auth]
  before_filter :init_url

  def init
    if session[:id].present? || cookies[:id].present?
      @id = session[:id] || cookies[:id]
      user = User.find(@id)
      @company_id = user.company_id
      @admin_flag = Company.exists?(:email => user.email) ? 1 : 0
    end
  end

  def login
    $c_code = ""
    if session[:id] || cookies[:id]
      redirect_to "/user"
    end

    reset_session
  end

  def login_complete
    authorized_user = User.authenticate(params[:email],params[:password])
    reset_session

    if authorized_user
      if authorized_user.delete_flag == 1
	reset_session
	flash[:notice] = "ユーザー名かパスワードに誤りがあります"
	redirect_to "/login"
      else
	if params[:remember].to_i == 1 
	  cookies.permanent[:id] = authorized_user.id
	  cookies.permanent[:email] = authorized_user.email
	else
	  session[:id] = authorized_user.id
	end

	verified = authorized_user.verified
	flash[:notice] = "" 

	if verified == 0
	  redirect_to "/update"
	else
	  redirect_to "/user"
	end
      end
    else
      flash[:notice] = "ユーザー名かパスワードに誤りがあります"
      render "login"
    end
  end

  def logout
    session[:id] = nil
    cookies.delete :id
    cookies.delete :email
    reset_session

    redirect_to '/login'
  end

  def index
    @placeholder = "+5 会議の資料作成ありがとう！急なお願いだったのに迅速な対応におどろき！#speed #資料良かった #いつのまにかパワポスキルあがってる"

    hashtags = Company.find(@company_id).hashtags
    if hashtags.blank?
      @hashtags = ["leadership","hardwork","creativity","positivity","teamwork"] 
    else
      @hashtags = hashtags.split(",")
    end

    @user = User.find(@id)
    @users = User.where(:company_id => @company_id, :delete_flag => 0) 

    today = Date.today
    @birthday_users = @users.where('MONTH(birthday)=? AND DAYOFMONTH(birthday)=?', today.month, today.day)
    
    posts = Post.where(:company_id => @company_id, :delete_flag => 0).order("update_time desc")

    limit = 5
    page = params[:page] || 1
    @total_items = posts.count
    @total_pages = (@total_items/limit.to_f).ceil

    if page.to_i <= 1
      page = 1
      offset = 0
    else
      offset = (page.to_i * limit) - limit
    end

    posts = posts.offset(offset).limit(limit)

    @page_now = params[:page].to_i
    if @page_now == 0
      @page_now = 1
    end
    @previous_page = @page_now - 1
    @next_page = @page_now + 1

    @posts = []
    data = {}

    posts.each do | post |
      comments = Comment.where(:post_id => post.id, :delete_flag => 0)
      kudos = Kudos.where(:post_id => post.id, :kudos => 1, :delete_flag => 0)

      data = {
	id:		post.id,
	user_id:	post.user_id,
	user_name:	post.user.name,
	receiver_name:	post.receiver.name,
	user_img:	post.user.img_src,
	receiver_img:	post.receiver.img_src,
	points:		post.points,
	description:	post.description,
	hashtags:	post.hashtags,
	comments:	comments,
	kudos:		kudos,
	create_time:	post.create_time.strftime("%Y/%m/%d %H:%M:%S")
      }

      @posts << data
    end

    top_givers = Post.where(company_id: @company_id).group(:user_id).order("count_all desc").limit(5).count

    @top_givers = []
    top_givers.each do | k, v |
      user = User.find(k)
      data = { name: user.name, img_src: user.img_src, count: v }
      @top_givers << data
    end

    top_receivers = Post.where(company_id: @company_id).group(:receiver_id).order("count_all desc").limit(5).count

    @top_receivers = []
    top_receivers.each do | k, v |
      user = User.find(k)
      data = { name: user.name, img_src: user.img_src, count: v }
      @top_receivers << data
    end

    @top_hashtags = Hashtag.where(company_id: @company_id).group(:hashtag).order("count_id desc").limit(7).count("id")
  end

  def give_points
    @users = User.where(:company_id => @company_id, :delete_flag => 0) 
    @user = User.find(@id)

    points = params[:description].scan(/\+[^\s|　]+/).first.to_i
    params[:user_id] = @id
    params[:company_id] = @company_id
    params[:points] = points
    
    if (params[:receiver_id].present?)
      if (points <= @user[:out_points])
	@user.out_points -= points 
	@user.save

	hashtags = params[:description].scan(/\#[^\s|　]+/)
	receiver = User.find(params[:receiver_id])
	receiver.in_points += params[:points]
	receiver.save

	UserMailer.receive_points_email({
	  receiver: receiver.name, 
	  email: receiver.email,
	  giver: @user.name,
	  points: params[:points],
	  prizy_url: @prizy_url + "/user"
	}).deliver_later

	post = Post.new
	post.save_record(params)
	params[:post_id] = post.id

	hashtags.each do | tag |
	  params[:hashtag] = tag 
	  hashtag = Hashtag.new
	  hashtag.save_record(params)
	end
      else
	flash[:notice] = "ポイントが足りません"
      end
    end
    redirect_to '/user'
  end

  def give_comments 
    params[:company_id] = @company_id
    params[:user_id] = @id

    res = Comment.new
    res.save_record(params)
    redirect_to "/user"
  end

  def give_kudos
    params[:user_id] = @id

    kudo = Kudos.where(:user_id => @id, :post_id => params[:post_id]).first

    if kudo.present?
      kudo.kudos = params[:kudos]
      kudo.save
    else
      res = Kudos.new
      res.save_record(params)
    end

    redirect_to "/user"
  end

  def profile
    @user = User.find(@id)
    posts = Post.where(:receiver_id => @id, :delete_flag => 0).order("update_time desc")

    limit = 5
    page = params[:page] || 1
    @total_items = posts.count
    @total_pages = (@total_items/limit.to_f).ceil

    if page.to_i <= 1
      page = 1
      offset = 0
    else
      offset = (page.to_i * limit) - limit
    end

    posts = posts.offset(offset).limit(limit)

    @page_now = params[:page].to_i
    if @page_now == 0
      @page_now = 1
    end
    @previous_page = @page_now - 1
    @next_page = @page_now + 1

    @posts = []
    data = {}

    posts.each do | post |
      comments = Comment.where(:post_id => post.id, :delete_flag => 0)
      kudos = Kudos.where(:post_id => post.id, :kudos => 1, :delete_flag => 0)

      data = {
	id:   post.id,
	user_id:  post.user_id,
	user_name:  post.user.name,
	receiver_name:  post.receiver.name,
	user_img: post.user.img_src,
	receiver_img: post.receiver.img_src,
	points:   post.points,
	description:  post.description,
	hashtags: post.hashtags,
	comments: comments,
	kudos:    kudos,
	create_time:  post.create_time.strftime("%Y/%m/%d %H:%M:%S")
      }

      @posts << data
    end

    top_givers = Post.where(receiver_id: @id).group(:user_id).order("count_all desc").limit(5).count

    @top_givers = []
    top_givers.each do | k, v |
      user = User.find(k)
      data = { name: user.name, img_src: user.img_src, count: v }
      @top_givers << data
    end

    @top_hashtags = Hashtag.where(receiver_id: @id).group(:hashtag).order("count_id desc").limit(7).count("id")
  end

  def given
    @user = User.find(@id)
    posts = Post.where(:user_id => @id, :delete_flag => 0).order("update_time desc")

    limit = 5
    page = params[:page] || 1
    @total_items = posts.count
    @total_pages = (@total_items/limit.to_f).ceil

    if page.to_i <= 1
      page = 1
      offset = 0
    else
      offset = (page.to_i * limit) - limit
    end

    posts = posts.offset(offset).limit(limit)

    @page_now = params[:page].to_i
    if @page_now == 0
      @page_now = 1
    end
    @previous_page = @page_now - 1
    @next_page = @page_now + 1

    @posts = []
    data = {}

    posts.each do | post |
      comments = Comment.where(:post_id => post.id, :delete_flag => 0)
      kudos = Kudos.where(:post_id => post.id, :kudos => 1, :delete_flag => 0)

      data = {
  id:   post.id,
  user_id:  post.user_id,
  user_name:  post.user.name,
  receiver_name:  post.receiver.name,
  user_img: post.user.img_src,
  receiver_img: post.receiver.img_src,
  points:   post.points,
  description:  post.description,
  hashtags: post.hashtags,
  comments: comments,
  kudos:    kudos,
  create_time:  post.create_time.strftime("%Y/%m/%d %H:%M:%S")
      }

      @posts << data
    end

    top_givers = Post.where(user_id: @id).group(:receiver_id).order("count_all desc").limit(5).count

    @top_givers = []
    top_givers.each do | k, v |
      user = User.find(k)
      data = { name: user.name, img_src: user.img_src, count: v }
      @top_givers << data
    end

    @top_hashtags = Hashtag.where(user_id: @id).group(:hashtag).order("count_id desc").limit(7).count("id")
  end

  def rewards
    @user = User.find(@id)
    @rewards = Reward.where(:company_id => @user.company_id, :delete_flag => 0).order("points").order("title")
  end

  def rewards_request
    data = {
      :company_id   => @company_id,
      :user_id	    => @id,
      :reward_id    => params["reward_id"],
      :status	    => 0
    }

    res = RequestReward.new
    res.save_record(data)

    user = User.find(@id)
    user.in_points -= res.reward.points
    user.save

    data[:username] = user.name
    data[:owner] = user.company.owner
    data[:email] = user.company.email
    data[:prizy_url] = @prizy_url + "/company/rewards/request#pending"

    CompanyMailer.request_reward_email(data).deliver_later

    redirect_to "/rewards"
  end

  def rewards_status
    @rewards = RequestReward.where(user_id: @id, status: 0, delete_flag: 0)
    @rewards_accepted = RequestReward.where(user_id: @id, status: 1).order("update_time desc")
    @rewards_rejected = RequestReward.where(user_id: @id, status: 9).order("update_time desc")
  end

  def rewards_cancel
    res = RequestReward.find(params[:id])

    if res.status == 0
      res.delete_flag = 1
      res.save

      user = User.find(@id)
      user.in_points += res.reward.points
      user.save
    end

    redirect_to "/rewards/status"
  end

  def update 
    update_details

    @user = User.find(@id)

    if @user.birthday?
      bday = @user.birthday.to_s.split("-")
      @b_year	= bday[0].to_i
      @b_month	= bday[1].to_i
      @b_day	= bday[2].to_i
    end
  end

  def invite
    $c_code = params[:c_code] if params[:c_code].present?

    if $c_code.present?
      invite_link = InviteLink.where(c_code: $c_code)

      unless invite_link.empty?
	update_details
	company = Company.find(invite_link[0][:company_id])
	@company_name = company.name
	@company_id = company.id
      else
	redirect_to "/login"
      end
    else
      redirect_to "/login"
    end
  end

  def update_details
    @fb_data = params[:fb_data].blank? ? 0:1
    
    @years = Util.years
    @b_year   = 0
    @b_month  = 0
    @b_day    = 0
  end
  
  def fb_auth
    fb_data = fb_auth_details

    if $c_code.present? 
      redirect_to invite_path(fb_data)
    else
      redirect_to update_path(fb_data)
    end
  end

  def fb_auth_details
    fb_user = User.koala(request.env['omniauth.auth']['credentials'])
    url = "https://graph.facebook.com/#{fb_user['id']}/picture?width=300&height=300"
    res = Net::HTTP.get_response(URI(url))
    fb_pic = res['location']

    fb_data = {
      :fb_data	  => 1,
      :fb_name	  => fb_user['name'],
      :fb_lname	  => fb_user['last_name'],
      :fb_fname	  => fb_user['first_name'],
      :fb_gender  => fb_user['gender'],
      :fb_pic	  => fb_pic 
    }

    if $c_code.present?
      fb_data[:c_code] = $c_code
    end

    return fb_data
  end

  def invite_complete
    update_complete_details
    data = {
      :email	  => params[:email],
      :name	  => params[:name],
      :password	  => params[:password],
      :prizy_url  => @prizy_url
    }
    UserMailer.invite_welcome_email(data).deliver_later
    logout
  end

  def update_complete 
    update_complete_details
    redirect_to_index
  end

  def update_complete_details
    url = request.original_url

    b_year = params[:b_year]
    b_month = params[:b_month]
    b_day = params[:b_day]
    params[:birthday] = DateTime.parse("#{b_year}-#{b_month}-#{b_day}").strftime("%Y-%m-%d") 

    verified = 0

    unless url.include?("invite")
      res = User.find(@id)
      verified = res.verified
    else
      res = User.new
      res.save_record(params)
    end

    if params[:img_src].present?
      unless params[:fb_data].to_i == 1
	src = params[:img_src]
	src_ext = File.extname(src.original_filename)

	s3 = Aws::S3::Resource.new
	obj = s3 .bucket(@s3_bucket).object("profile/user_#{res.id}_pic#{src_ext}")
	obj.upload_file src.tempfile, {acl: 'public-read'}

	params[:img_src] = obj.public_url
      end
    else
      if verified == 0
	params[:img_src] = "https://#{@s3_bucket}.s3-ap-northeast-1.amazonaws.com/common/noimg_pc.png" 
      end
    end

    params[:out_points] = 150 if verified == 0
    params[:verified] = 1 
      
    if url.include?("invite")
      res.img_src = params[:img_src]
      res.out_points = params[:out_points]
      res.verified = params[:verified]
      res.deliver_invite_mail = 3
      res.save
    else
      res.save_record(params)
    end
  end

  def forgot_password
  end

  def forgot_password_submit
    user = User.where("email LIKE '#{params[:email]}'").first

    if user.present?
      temp_password = SecureRandom.hex(4)
      user.save_record({:password => temp_password})

      data = {
	:email	  => params[:email],
	:password => temp_password,
	:prizy_url  => @prizy_url
      }

      UserMailer.reset_password(data).deliver_later
      redirect_to_index 
    else
      flash[:notice] = "The email you entered does not exist"
      render 'forgot_password'
    end
  end

  def redirect_to_index
    redirect_to "/user" 
  end
end
