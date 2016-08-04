#coding:utf-8
require 'util.rb'

class UsersController < ApplicationController
  before_filter :init, :authenticate_user, :except => [:login, :login_complete, :logout]
  before_filter :init_url

  def init
    if session[:user_id].present?
      @id = session[:user_id]
      @company_id = User.find(@id).company_id
    end
  end

  def login
    if session[:user_id]
      redirect_to "/user"
    end
  end

  def login_complete
    authorized_user = User.authenticate(params[:email],params[:password])
    reset_session
    if authorized_user
      session[:user_id] = authorized_user.id
      verified = authorized_user.verified
      flash[:notice] = "" 

      if verified == 0
	redirect_to "/update"
      else
	redirect_to "/user"
      end
    else
      flash[:notice] = "ユーザー名かパスワードに誤りがあります"
      flash[:color]= "invalid"
      render "login"
    end
  end

  def logout
    session[:user_id] = nil
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
    posts = Post.where(:company_id => @company_id, :delete_flag => 0).order("update_time desc")

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
	kudos:		kudos
      }

      @posts << data
    end
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
    #TODO: send accept/reject email to user
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
    @user = User.find(@id)
    @years = Util.years

    @b_year   = 0
    @b_month  = 0
    @b_day    = 0

    if @user.birthday?
      bday = @user.birthday.to_s.split("-")
      @b_year	= bday[0].to_i
      @b_month	= bday[1].to_i
      @b_day	= bday[2].to_i
    end
  end

  def update_complete 
    b_year = params[:b_year]
    b_month = params[:b_month]
    b_day = params[:b_day]
    params[:birthday] = DateTime.parse("#{b_year}-#{b_month}-#{b_day}").strftime("%Y-%m-%d") 

    res = User.find(@id)

    if params[:img_src].present?
      src = params[:img_src]
      src_ext = File.extname(src.original_filename)

      s3 = Aws::S3::Resource.new
      obj = s3 .bucket("btoa-img").object("profile/user_#{res.id}_pic#{src_ext}")
      obj.upload_file src.tempfile, {acl: 'public-read'}

      params[:img_src] = obj.public_url
    else
      if res.verified == 0
	params[:img_src] = "https://btoa-img.s3-ap-northeast-1.amazonaws.com/common/noimg_pc.png" 
      end
    end

    params[:out_points] = 150 if res.verified == 0
    params[:verified] = 1 
    
    res.save_record(params)
    redirect_to_index
  end

  def redirect_to_index
    redirect_to "/user" 
  end
end
