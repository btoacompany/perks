#coding:utf-8
require 'util.rb'
require 'open-uri'
require 'net/http'
require 'slack-notifier'
require 'json'

class UsersController < ApplicationController
  before_filter :init, :authenticate_user, :except => [:login, :login_complete, :logout, :invite, :invite_complete, :give_points_slack, :give_points_slack_response, :forgot_password, :forgot_password_submit, :fb_auth]
  before_filter :init_url

  def init
    if session[:id].present? || cookies[:id].present?
      @id = session[:id] || cookies[:id]
      user = User.find(@id)
      @company_id = user.company_id
      @admin_flag = Company.exists?(:email => user.email) ? 1 : 0
    end

    if params[:code].present?
      slack_code = params[:code]

      data = {
	:client_id  => "12258104198.88079493873",
	:code	    => params[:code],
	:client_secret	=> "d3cc97422eac0aefbf7c097a3647306c"
      }

      uri = URI.parse("https://slack.com/api/oauth.access")
      http = Net::HTTP.post_form(uri, data)
      userinfo = JSON.parse(http.body)
      
      slack = SlackToken.where(:team_id => userinfo["team_id"]).first
      
      if slack.blank?
	slack = SlackToken.new
	slack.token	    = userinfo["access_token"]
	slack.team_id	    = userinfo["team_id"]
	slack.webhooks_url  = userinfo["incoming_webhook"]["url"]
	slack.bot_token	    = userinfo["bot"]["bot_access_token"]
	slack.save
      else
	slack.token = userinfo["access_token"]
	slack.webhooks_url  = userinfo["incoming_webhook"]["url"]
	slack.bot_token	    = userinfo["bot"]["bot_access_token"]
	slack.save
      end
    end
  end

  def login
    $c_code = ""
    if session[:id] || cookies[:id]
      redirect_page("users", "index")
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
      	render 'login', :status => :unauthorized

      else
      	if params[:remember].to_i == 1 
      	  cookies.permanent[:id] = authorized_user.id
      	  cookies.permanent[:email] = authorized_user.email
      	else
      	  session[:id] = authorized_user.id
      	  session[:email] = authorized_user.email
      	end

      	verified = authorized_user.verified
      	flash[:notice] = "" 

      	if verified == 0
      	  redirect_page("users", "update")
      	else
      	  redirect_page("users", "index")
      	end
      end
    else
      flash[:notice] = "ユーザー名かパスワードに誤りがあります"
      render 'login', :status => :unauthorized
    end
  end

  def logout
    session[:id] = nil
    session[:email] = nil
    cookies.delete :id
    cookies.delete :email
    reset_session

    redirect_page("users", "login")
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
    @bonuses = Bonus.where(:company_id => @company_id, :delete_flag => 0) 

    # birthday user today
    today = Date.today
    @birthday_users = @users.where('MONTH(birthday)=? AND DAYOFMONTH(birthday)=?', today.month, today.day).where(delete_flag: 0)
    # upcoming birthday
    range_time = today.mday..today.end_of_month.mday
    b_users = @users.where('MONTH(birthday) = ?', today.month).where(delete_flag: 0)
    @b_users = []
    b_users.each do |bu|
      if range_time.cover?(bu.birthday.mday)
        @b_users << bu
      end
    end
    # definition for pnotify 
    @default_birthday = "2016-01-01"
    
    posts = Post.where(:company_id => @company_id, :privacy => 0, :delete_flag => 0)
    bonus_posts = Post.where(:company_id => @company_id, :privacy => 1, :delete_flag => 0).where("receiver_id = #{@user.id} OR user_id = #{@user.id}")

    all_posts = ((posts + bonus_posts).sort_by &:update_time).reverse
    posts_count = all_posts.count

    limit = 10
    page = params[:page] || 1
    @total_items = posts_count
    @total_pages = (@total_items/limit.to_f).ceil

    if page.to_i <= 1
      page = 1
      offset = 0
    else
      offset = (page.to_i * limit) - limit
    end

    all_posts = all_posts[offset, limit]
    posts = Post.where(id: all_posts.map(&:id)).order("update_time desc")

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
      	full_user_name:	"#{post.user.lastname} #{post.user.firstname}",
      	receiver_id:	post.receiver_id,
      	receiver_name:	post.receiver.name,
      	full_receiver_name: "#{post.receiver.lastname} #{post.receiver.firstname}",
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

    top_givers = Post.where(company_id: @company_id, delete_flag: 0).group(:user_id).order("count_all desc").limit(5).count

    @top_givers = []
    top_givers.each do | k, v |
      user = User.find(k)
      data = { name: "#{user.lastname} #{user.firstname}", img_src: user.img_src, count: v }
      @top_givers << data
    end

    top_receivers = Post.where(company_id: @company_id, delete_flag: 0).group(:receiver_id).order("count_all desc").limit(5).count

    @top_receivers = []
    top_receivers.each do | k, v |
      user = User.find(k)
      data = { name: "#{user.lastname} #{user.firstname}", img_src: user.img_src, count: v }
      @top_receivers << data
    end

    @top_hashtags = Hashtag.where(company_id: @company_id, delete_flag: 0).group(:hashtag).order("count_id desc").limit(7).count("id")

    @num_rewards = Reward.where(company_id: @company_id, delete_flag: 0).count
    @num_bonus = Bonus.where(company_id: @company_id, delete_flag: 0).count

    @popular_rewards = []
    if @user.company.plan > 0
      rewards_list = RequestReward.where(company_id: @company_id, delete_flag: 0).group(:rewards_prizy_id).order("count_id desc").count("id")
      if rewards_list.present?
        rewards_list.each do |key, value|
          if key.present?
          @popular_rewards << RewardsPrizy.find(key)
          end
        end
        if @popular_rewards.blank?
          @popular_rewards = RewardsPrizy.all
        end
      else
        @popular_rewards = RewardsPrizy.all
      end
    else
      rewards_list = RequestReward.where(company_id: @company_id, delete_flag: 0).group(:reward_id).order("count_id desc").count("id")
      rewards_list.each do |key, value|
        @popular_rewards << Reward.find(key)
      end
    end

    # statistics for user
    last_week =  Date.today.prev_week.beginning_of_week..Date.today.prev_week.end_of_week
    this_week = Date.today.beginning_of_week..Date.today.end_of_week

    @last_week_posts = Post.where(company_id: @company_id, delete_flag: 0, receiver_id: @user.id, create_time: last_week).count
    if @last_week_posts == 0
      @last_week_posts = 1
    end
    @this_week_posts = Post.where(company_id: @company_id, delete_flag: 0, receiver_id: @user.id, create_time: this_week).count
    @ratio = (@last_week_posts - @this_week_posts) / @last_week_posts * 100
  end

  def give_points_slack
    slack = SlackToken.where(:team_id => params["team_id"]).first
    @slack_token = slack[:token]
    @slack_webhooks = slack[:webhooks_url]

    slack_user_info_data = {
      :user	    => params["user_id"],
      :token	    => @slack_token,
    }

    slack_user_list_data = {
      :token => @slack_token,
      :presence => 1,
    }

    uri = URI.parse("https://slack.com/api/users.info")
    http = Net::HTTP.post_form(uri, slack_user_info_data)
    userinfo = JSON.parse(http.body)

    uri = URI.parse("https://slack.com/api/users.list")
    http = Net::HTTP.post_form(uri, slack_user_list_data)
    userlist = JSON.parse(http.body)

    begin
      email = userinfo["user"]["profile"]["email"]
      error = 0
      #email = "c_a@btoa-company.com"

      user = User.find_by_email(email)

      unless user.blank?
      	params[:user_id] = user.id 
      	params[:company_id] = user.company_id
      	params[:description] = params["text"]

      	receiver_name = params["text"].scan(/\@[^\s|　]+/).first.gsub("@","")
      	receiver = ""

      	userlist["members"].each do | member |
      	  if member["name"] == receiver_name
      	    receiver_email = member["profile"]["email"] 
      	    if receiver_email == email
      	      flash[:notice] = "Nice try, but you cannot give points to yourself!"
      	      error = 1
      	    else
      	      receiver = User.where(:email => receiver_email, :delete_flag => 0).first
      	    end

      	    break
      	  end
      	end
      	
      	if error == 0
      	  unless receiver.blank?
      	    points = params["text"].scan(/\+[^\s|　]+/).first.gsub("+","").to_i
      	    params[:points] = points
      	    params[:receiver_id] = receiver.id

      	    if (points <= user[:out_points])
      	      user.out_points -= params[:points]
      	      user.save

      	      hashtags = params["text"].scan(/\#[^\s|　]+/)
      	      receiver.in_points += params[:points]
      	      receiver.save

      	      UserMailer.receive_points_email({
            		receiver: receiver.name, 
            		email: receiver.email,
            		giver: user.name,
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

              ios_push_notif(receiver.id, "#{user.firstname}さんから「ホメ」が届きました。")

      	      slack_notif = Slack::Notifier.new(@slack_webhooks) 
      	      slack_notif.ping("#{params[:user_name]}さんが#{receiver_name}さんに感謝を伝えました。\n #{receiver_name}さんの頑張りは<a href='https://www.prizy.me'>コチラ</a> から。")

      	      flash[:notice] = "#{receiver_name}さんにボーナスを贈りました！"
      	    else
	      flash[:notice] = "投稿できませんでした。手持ちのポイント数が足りません。 今月は#{user.out_points}ポイント残っています。"
      	    end
      	  else
      	    flash[:notice] = "投稿できませんでした。ユーザーがPrizyに登録していません！\n Prizyへの招待リンクを贈ってあげましょう。\n#{user.company.invite_link}"
      	  end
      	end	
      else
      	team_domain = params["team_domain"].upcase
      	flash[:notice] = "Your email #{email} is not yet registered to #{team_domain} Prizy"
      end
    rescue Exception => e
      logger.debug e.message
      flash[:notice] = "投稿できませんでした。入力に不備があります。\n （入力例)\n「/prizy +20 @tanaka.naoki 会議の資料つくってくれてありがとう。グラフィックの出来が半端なかった！！#急成長 #デザインセンス抜群 #またお願いするわww」"
    end

    render :layout => false
  end

  def give_points
    parse_points(params)
    redirect_page("users", "index")
  end

  def parse_points(params)
    @users = User.where(:company_id => @company_id, :delete_flag => 0) 
    @user = User.find(@id)
    error = 0

    points = params[:description].scan(/\+[^\s|　]+/).first.to_i
    params[:user_id] = @id
    params[:company_id] = @company_id
    params[:points] = points

    if (params[:receiver_id].present?)
      if params[:receiver_id].include?(@id)
	flash[:notice] = "自分にポイントあげることができません。"
	error = 1
      end

      if error == 0
	receiver_ids = params[:receiver_id]

	receiver_ids.each do | receiver_id |
	  params[:receiver_id] = receiver_id

	  if (points <= @user[:out_points])
	    @user.out_points -= points 
	    @user.save

	    hashtags = params[:description].scan(/\#[^\s|　]+/)
	    receiver = User.find(receiver_id.to_i)

	    receiver.in_points += params[:points]
	    receiver.save

	    unless params[:type] == "comment"
	      post = Post.new
	      post.save_record(params)
	      params[:post_id] = post.id

	      UserMailer.receive_points_email({
		receiver: receiver.name, 
		email: receiver.email,
		giver: @user.name,
		points: params[:points],
		prizy_url: @prizy_url + "/user"
	      }).deliver_later

	    end

	    hashtags.each do | tag |
	      params[:hashtag] = tag 
	      hashtag = Hashtag.new
	      hashtag.save_record(params)
	    end

	    ios_push_notif(receiver.id, "#{@user.firstname}さんから「ホメ」が届きました。")

	  else
	    flash[:notice] = "ポイントが足りません"
	  end
	end
      end

    end
  end

  def give_comments 
    params[:company_id] = @company_id
    params[:user_id] = @id

    res = Comment.new
    res.save_record(params)

    user = User.find(@id)

    params[:receiver_id] = Post.find(res.post_id).receiver_id
    params[:description] = params["comments"]
    params[:points] = params["comments"].scan(/\+[^\s|　]+/).first
    params[:type] = "comment"

    if params[:points].present?
      parse_points(params)
    end

    ios_push_notif(params[:receiver_id], "#{user.firstname}さんがコメントしました。")

    redirect_page("users", "index")
  end

  def give_kudos
    params[:user_id] = @id

    kudo = Kudos.where(:user_id => @id, :post_id => params[:post_id], delete_flag: 0).first

    if kudo.present?
      kudo.kudos = params[:kudos]
      kudo.save
    else
      res = Kudos.new
      res.save_record(params)
    end

    redirect_page("users", "index")
  end

  def ios_push_notif(id, message)
    devices = IosToken.where(:user_id => id)

    devices.each do | device |
      sns_message = {
        'default': message,
        'message': {
          'APNS_SANDBOX': {
            'aps': {
              'alert': 'inner message',
              'sound': 'mySound.caf'
            }
          }
        }
      }

      sns = Aws::SNS::Client.new
      sns.publish(
        target_arn: device.arn, 
        message: sns_message.to_json, 
        message_structure: "json"
      )
    end
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
      	receiver_id: post.receiver_id,
      	full_user_name:	"#{post.user.lastname} #{post.user.firstname}",
      	full_receiver_name: "#{post.receiver.lastname} #{post.receiver.firstname}",
      	points:   post.points,
      	description:  post.description,
      	hashtags: post.hashtags,
      	comments: comments,
      	kudos:    kudos,
      	create_time:  post.create_time.strftime("%Y/%m/%d %H:%M:%S")
      }

      @posts << data
    end

    top_givers = Post.where(receiver_id: @id, delete_flag: 0).group(:user_id).order("count_all desc").limit(5).count

    @top_givers = []
    top_givers.each do | k, v |
      user = User.find(k)
      data = { name: "#{user.lastname} #{user.firstname}", img_src: user.img_src, count: v }
      @top_givers << data
    end

    @top_hashtags = Hashtag.where(receiver_id: @id, delete_flag: 0).group(:hashtag).order("count_id desc").limit(7).count("id")
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
      	receiver_id: post.receiver_id,
      	full_user_name:	"#{post.user.lastname} #{post.user.firstname}",
      	full_receiver_name: "#{post.receiver.lastname} #{post.receiver.firstname}",
      	points:   post.points,
      	description:  post.description,
      	hashtags: post.hashtags,
      	comments: comments,
      	kudos:    kudos,
      	create_time:  post.create_time.strftime("%Y/%m/%d %H:%M:%S")
      }

      @posts << data
    end

    top_givers = Post.where(user_id: @id, delete_flag: 0).group(:receiver_id).order("count_all desc").limit(5).count

    @top_givers = []
    top_givers.each do | k, v |
      user = User.find(k)
      data = { name: user.name, img_src: user.img_src, count: v }
      @top_givers << data
    end

    @top_hashtags = Hashtag.where(user_id: @id, delete_flag: 0).group(:hashtag).order("count_id desc").limit(7).count("id")
  end

  def rewards
    @user = User.find(@id)
    @rewards = Reward.where(:company_id => @user.company_id, :delete_flag => 0).order("points").order("title")
    @rewards_prizy = RewardsPrizy.where(:delete_flag => 0)
  end

  def rewards_request
    data = {
      :company_id   => @company_id,
      :user_id	    => @id,
      :status	    => 0
    }

    points = 0

    if params["type"] == "prizy"
      data[:reward_prizy_id] = params["reward_id"]
      data[:status] = 1
    else
      data[:reward_id] = params["reward_id"]
    end

    res = RequestReward.new
    res.save_record(data)

    user = User.find(@id)

    if params["type"] == "prizy"
      points = res.rewards_prizy.points

      reward_data = {
	:reward	  => res.rewards_prizy.title,
	:points	  => res.rewards_prizy.points,
	:username => user.name,
	:email	  => user.email,
	:company  => user.company.name
      }

      UserMailer.redeem_prizy_reward(reward_data).deliver_later
    else
      points = res.reward.points
    end

    user.in_points -= points 
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
    points = 0

    if res.status == 0
      res.delete_flag = 1
      res.save

      if res.rewards_prizy.present? 
	points = res.rewards_prizy.points
      else
	points = res.reward.points
      end

      user = User.find(@id)
      user.in_points += points 
      user.save
    end

    redirect_to "/rewards/status"
  end

  def update 
    session[:redirect] = nil
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
    session[:redirect] = nil
    $c_code = params[:c_code] if params[:c_code].present?

    if $c_code.present?
      invite_link = InviteLink.where(c_code: $c_code, delete_flag: 0)

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

    if session[:redirect].nil?
      data = {
      	:email	    => params[:email],
      	:name	    => params[:name],
      	:password   => params[:password],
      	:prizy_url  => @prizy_url
      }
      UserMailer.invite_welcome_email(data).deliver_later
      logout
    end
  end

  def update_complete 
    update_complete_details

    if session[:redirect].nil?
      redirect_to_index
    end
  end

  def update_complete_details
    name_exist = "そのユーザー名はすでに使われております。他のユーザー名をご指定ください。"
    session[:redirect] = nil

    url = request.original_url
    verified = 0

    unless url.include?("invite")
      username_exist = User.where(name: params[:name], company_id: @company_id)
      res = User.find(@id)
      verified = res.verified

      unless res.name == params[:name]
      	if username_exist.present?
      	  flash[:notice] = name_exist 
      	  session[:redirect] = 1
      	  redirect_to "/update" and return
      	end
      end
    else
      username_exist = User.where(name: params[:name], company_id: params[:company_id])
      if username_exist.present?
      	flash[:notice] = name_exist 
      	session[:redirect] = 1
      	redirect_to "/invite" and return
      end

      res = User.new
      res.save_record(params)
    end

    b_year = params[:b_year]
    b_month = params[:b_month]
    b_day = params[:b_day]
    params[:birthday] = DateTime.parse("#{b_year}-#{b_month}-#{b_day}").strftime("%Y-%m-%d") 

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
    user = User.where("email LIKE '#{params[:email]}' AND delete_flag = 0").first

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

  def give_bonus
    bonus_title = params[:bonus_title].gsub(/\s+/, "").split("_")

    if params[:bonus_points].present?
      points = params[:bonus_points].to_i
      bonus_title.pop
    else
      points = (bonus_title.pop).to_i
    end

    params[:bonus_title] = bonus_title.join("")

    @user = User.find(@id)

    if (params[:bonus_receiver_id].present?)
      if (points <= @user.company.bonus_points)
      	@user.company.bonus_points -= points.to_i 
      	@user.company.save

      	comments = [ "+#{points}", params[:bonus_comments] ].reject { |e| e.to_s.empty? }
      	comments << "#bonus_challenge ##{params[:bonus_title]}"
      	params[:bonus_comments] = comments.join(" ")
      	hashtags = params[:bonus_comments].scan(/\#[^\s|　]+/)

      	receiver = User.find(params[:bonus_receiver_id])
      	receiver.in_points += points.to_i
      	receiver.save

      	UserMailer.receive_points_email({
      	  receiver: receiver.name, 
      	  email: receiver.email,
      	  giver: @user.name,
      	  points: points,
      	  prizy_url: @prizy_url + "/user"
      	}).deliver_later

      	post = Post.new
      	data = {
      	  :company_id	    => @company_id,
      	  :user_id	    => @id,
      	  :receiver_id	    => params[:bonus_receiver_id],
      	  :points	    => points,
      	  :description	    => params[:bonus_comments],
      	  :privacy	    => params[:privacy],
      	  :post_type	    => 1
      	}

      	post.save_record(data)
      	data[:post_id] = post.id

      	hashtags.each do | tag |
      	  data[:hashtag] = tag 
      	  hashtag = Hashtag.new
      	  hashtag.save_record(data)
      	end
      else
	     flash[:notice] = "ポイントが足りません"
      end
    end

    redirect_to_index
  end

  def bonus
    user = User.find(@id)
    @bonus = Bonus.where(:company_id => user.company_id, :delete_flag => 0).order("points").order("title")
  end

  def delete_comment
    comment = Comment.find(params[:comment_id])
    comment.delete_record

    redirect_to "/user" 
  end

  def delete_post
    #TODO: delete design
    post_id = params[:post_id]

    post = Post.where(id: post_id).update_all(delete_flag: 1)
    comments = Comment.where(post_id: post_id).update_all(delete_flag: 1)
    kudos = Kudos.where(post_id: post_id).update_all(delete_flag: 1)
    hashtags = Hashtag.where(post_id: post_id).update_all(delete_flag: 1)

    redirect_to "/user" 
  end

  def redirect_to_index
    redirect_to "/user" 
  end
end
