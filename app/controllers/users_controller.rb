#coding:utf-8
require 'util.rb'

class UsersController < ApplicationController
  before_filter :init, :authenticate_user, :except => [:login, :login_complete, :logout]

  def init
    if session[:user_id].present?
      @id = session[:user_id]
      @company_id = User.find(@id).company_id
    end
  end

  def login
    if session[:user_id]
      redirect_to "/"
    end
  end

  def login_complete
    authorized_user = User.authenticate(params[:email],params[:password])
    reset_session
    if authorized_user
      session[:user_id] = authorized_user.id
      verified = authorized_user.verified
      flash[:notice] = "" 

=begin
      if verified == 0
	redirect_to "/update"
      else
	redirect_to "/"
      end
=end      
	redirect_to "/"
    else
      flash[:notice] = "Invalid Email or Password"
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
    hashtags = Company.find(@company_id).hashtags
    if hashtags.nil?
      @hashtags = ["leadership","hardwork","creativity","positivity","teamwork"] 
    else
      @hashtags = hashtags.split(",")
    end

    @user = User.find(@id)
    @users = User.where(:company_id => @company_id, :delete_flag => 0) 
    @posts = Post.where(:company_id => @company_id, :delete_flag => 0).order("update_time desc")
  end

  def give_points
    @users = User.where(:company_id => @company_id, :delete_flag => 0) 
    @user = User.find(@id)

    points = params[:description].scan(/\+[^\s|　]+/).first.to_i
    #params[:receiver_id] = rand(1..@users.count) 
    params[:user_id] = @id
    params[:company_id] = @company_id
    params[:points] = points

    unless (@user[:out_points] <= 0)
      @user.out_points -= points 
      @user.save

      hashtags = params[:description].scan(/\#[^\s|　]+/)

      receiver = User.find(params[:receiver_id])
      receiver.in_points += params[:points]
      receiver.save

      post = Post.new
      post.save_record(params)
      params[:post_id] = post.id

      hashtags.each do | tag |
	params[:hashtag] = tag 
	hashtag = Hashtag.new
	hashtag.save_record(params)
      end
      redirect_to '/user'
    else
      @posts = Post.where(:company_id => @company_id, :delete_flag => 0).order("update_time desc")
      flash[:notice] = "Insufficient Points"
      render "index"
    end
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

    params[:out_points] = 150 if res.verified == 0
    params[:verified] = 1 
    
    res.save_record(params)
    redirect_to_index
  end

  def redirect_to_index
    redirect_to "/" 
  end
end
