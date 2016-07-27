#coding:utf-8
require 'securerandom'

class CompanyController < ApplicationController
  before_filter :init, :authenticate_company, :except => [:login, :login_complete, :logout, :create, :create_complete]

  def init
    @id = session[:company_id] if session[:company_id].present? 
  end

  def login
    if session[:company_id]
      @id = session[:id]
      redirect_to "/company"
    end
  end

  def login_complete
    authorized_user = Company.authenticate(params[:email],params[:password])
    reset_session
    if authorized_user
      session[:company_id] = authorized_user.id
      flash[:notice] = "" 
      redirect_to "/company"
    else
      flash[:notice] = "Invalid Username or Password"
      flash[:color]= "invalid"
      render "login"
    end
  end

  def logout
    session[:company_id] = nil
    reset_session
    redirect_to '/company/login'
  end

  def index
    #do nothing
  end

  def create
    #do nothing
  end

  def create_complete
    params[:hashtags] = hashtags_fix(params[:hashtags])
    result = Company.new
    result.save_record(params)
    session[:id] = result.id
    redirect_to_index
  end

  def details 
    @company = Company.find(@id)
  end

  def edit
    @company = Company.find(@id)
  end

  def edit_complete
    params[:hashtags] = hashtags_fix(params[:hashtags])
    res = Company.find(@id)
    res.save_record(params)
    
    if params[:password].present?
      redirect_to '/company/logout'
    else
      redirect_to_index
    end
  end

  def hashtags_fix(hashtags)
    arr_hashtags = ""
    if hashtags.present?
      arr_hashtags = hashtags.split(",")
      arr_hashtags.reject! { | tag | tag.empty? }
      arr_hashtags.uniq!
      arr_hashtags.map{ | tag | tag.gsub(" ", "").strip }.compact.join(",")
    else
      arr_hashtags="leadership,hardwork,creativity,positivity,teamwork"
    end
  end


  def employees
    @users = User.where(:company_id => @id, :delete_flag => 0)
  end

  def add_employees
    #do nothing
  end

  def add_employees_complete
    emails = params[:emails].split("\r\n")
    emails.map{ |s| s.strip }
    company = Company.find(@id)

    emails.each do | email |
      temp_password = SecureRandom.hex(4)
      name = email.split("@")[0]

      @data = {
	:company_id	=> @id,
	:company_name	=> company.name,
	:company_owner	=> company.owner,
	:email		=> email,
	:password	=> temp_password,
	:name		=> name,
	:img_src	=> "https://btoa-img.s3-ap-northeast-1.amazonaws.com/common/noimg_pc.png"
      }

      @user = User.new
      @user.save_record(@data)

      respond_to do |format|
	if @user.save
	  # Tell the UserMailer to send a welcome email after save
	  UserMailer.verify_account(@data).deliver_now
	  format.html { }
	  format.json { render json: @user, status: :created, location: @user }
	else
	  format.html { render action: 'new' }
	  format.json { render json: @user.errors, status: :unprocessable_entity }
	end
      end
    end

    redirect_to "/company/employees"
  end

  def delete_employees 
    result = User.find(params[:id])
    result.delete_record
    redirect_to_index 
  end

  def rewards
    @rewards = Reward.where(:company_id => @id, :delete_flag => 0)
  end

  def add_rewards
    #do nothing
  end

  def add_rewards_complete
    params[:company_id] = @id

    @user = Reward.new
    @user.save_record(params)
    redirect_to '/company/rewards'
  end

  def edit_rewards
    @reward = Reward.find(params[:reward_id])
  end

  def edit_rewards_complete
    params[:company_id] = @id

    result = Reward.find(params[:reward_id])
    result.save_record(params)
    redirect_to '/company/rewards'
  end

  def delete_rewards 
    result =  Reward.find(params[:id])
    result.delete_record
    redirect_to '/company/employees'
  end

  def rewards_request
    @rewards = RequestReward.where(company_id: @id, status: 0, delete_flag: 0)
    @rewards_accepted = RequestReward.where(:company_id => @id, :status => 1).order("update_time desc")
    @rewards_rejected = RequestReward.where(:company_id => @id, :status => 9).order("update_time desc")
  end

  def rewards_request_action
    #TODO: send accept/reject email to user
    res = RequestReward.find(params[:id])
    
    if res.delete_flag == 0
      if params[:status].to_i == 1
	res.status = 1
      elsif params[:status].to_i == 9
	res.status = 9
      else
	res.status = 0
      end
      res.save
    end

    redirect_to "/company/rewards/request"
  end

  def redirect_to_index
    redirect_to "/company" 
  end
end
