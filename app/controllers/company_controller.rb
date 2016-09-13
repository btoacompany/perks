#coding:utf-8
require 'securerandom'

class CompanyController < ApplicationController
  before_filter :init, :authenticate_company, :except => [:login, :login_complete,
  :logout, :create, :create_complete, :forgot_password, :forgot_password_submit]
  before_filter :init_url

  def init
    if session[:company_id].present? || cookies[:company_id].present?
      @id = session[:company_id] || cookies[:company_id]
    end
  end

  def login
    flash[:notice] = "" 
    if session[:company_id] || cookies[:company_id]
      redirect_to "/company"
    end
  end

  def login_complete
    authorized_user = Company.authenticate(params[:email],params[:password])
    reset_session
    if authorized_user
      if params[:remember].to_i == 1 
	cookies.permanent[:company_id] = authorized_user.id
      else
	session[:company_id] = authorized_user.id
      end

      flash[:notice] = "" 
      redirect_to "/company"
    else
      flash[:notice] = "ユーザー名かパスワードに誤りがあります"
      render "login"
    end
  end

  def logout
    session[:company_id] = nil
    cookies.delete :company_id
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
    begin
      params[:prizy_url] = @prizy_url + "/company/login"
      params[:hashtags] = hashtags_fix(params[:hashtags])

      company = Company.new
      company.save_record(params)

      c_code = (Time.now.to_i).to_s + "_" + (company.id).to_s
      company.invite_link = @prizy_url + "/invite?c_code=" + c_code
      company.save

      if company.save
	CompanyMailer.welcome_email(params).deliver_later

	invite_link = InviteLink.new
	invite_link.save_record({
	  :company_id   => company.id,
	  :c_code	=> c_code
	})

	reward = Reward.new
	reward.save_record({
	  :company_id   => company.id,
	  :title	=> "Starbucks eGift (500円分)",
	  :description  => "毎日のちょっとした贅沢に。スターバックのコーヒー片手に仕事の疲れをリフレッシュしたい！そんな方におすすめのギフト券です。（※ギフト券は承認後、メールで届きます。)",
	  :points	=> 500,
	  :img_src      => @s3_url + "/common/img_07.png"
	})

	reward = Reward.new
	reward.save_record({
	  :company_id   => company.id,
	  :title	=> "Amazonギフト券(1000円分)",
	  :description  => "ちょっとしたお買い物にとっても便利なAmazonギフト券。ちょっぴりお得になる素敵なプレセントです！（※承認後メールで電子ギフト券が届きます。)",
	  :points	=> 1000,
	  :img_src      => @s3_url + "/common/img_05.png"
	})
      end
      session[:company_id] = company.id
      redirect_to "/company/details"
    rescue Exception => e
      puts e.message
      flash[:notice] = "メールアドレスはすでにありました"
      render 'create'
    end
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
    @company = Company.find(@id)
    @users = User.where(:company_id => @id, :delete_flag => 0)
  end

  def add_employees
    #do nothing
  end

  def add_employees_complete
    emails = params[:emails].split("\r\n")
    emails.map{ |s| s.strip }
    company = Company.find(@id)
    existing_emails = User.uniq.pluck(:email)
    @duplicate_emails = []

    emails.each do | email |
      if existing_emails.include?(email)
	@duplicate_emails << email
      else
	temp_password = SecureRandom.hex(4)
	name = email.split("@")[0]

	@data = {
	  :company_id	=> @id,
	  :company_name	=> company.name,
	  :company_owner=> company.owner,
	  :email	=> email,
	  :password	=> temp_password,
	  :name		=> name,
	  :img_src	=> "https://btoa-img.s3-ap-northeast-1.amazonaws.com/common/noimg_pc.png",
	  :prizy_url	=> @prizy_url + "/login"
	}
	@user = User.new
	@user.save_record(@data)
      end
    end

    if @duplicate_emails.present?
      flash[:notice] = "#{@duplicate_emails.join(", ")} はすでに登録されています。<br>下記のリストに表示されていない場合、メールアドレが変更・削除された恐れがあります。<br>再度追加する場合はPrizy運営事務局にご連絡ください。"
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
  end

  def add_rewards_complete
    params[:company_id] = @id
    params[:img_src] = @s3_url + "/common/img_01.png"

    @user = Reward.new
    @user.save_record(params)
    redirect_to '/company/rewards'
  end

  def edit_rewards
    @reward = Reward.find(params[:reward_id])
    if @reward[:img_src].match(/img_07|img_05/)
      redirect_to "/company/rewards"
    end
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
    res = RequestReward.find(params[:id])
    params[:name] = res.user.name
    params[:email] = res.user.email
    params[:prizy_url] = @prizy_url + "/rewards/status#accepted"

    if res.delete_flag == 0
      if params[:status].to_i == 1 
	res.status = 1 #accept
	UserMailer.reward_approved_email(params).deliver_later
      elsif params[:status].to_i == 9 
	res.status = 9 #reject
      else
	res.status = 0 #pending
      end
      res.save
    end

    redirect_to "/company/rewards/request"
  end

  def forgot_password
  end

  def forgot_password_submit
    company = Company.where("email LIKE '#{params[:email]}'").first
    flash[:notice] = "" 

    if company.present?
      temp_password = SecureRandom.hex(4)
      company.save_record({:password => temp_password})

      data = {
	:email	  => params[:email],
	:password => temp_password,
	:prizy_url  => @prizy_url + "/company"
      }

      CompanyMailer.reset_password(data).deliver_later
      redirect_to_index 
    else
      flash[:notice] = "The email you entered does not exist"
      render 'forgot_password'
    end
  end

  def redirect_to_index
    redirect_to "/company" 
  end
end
