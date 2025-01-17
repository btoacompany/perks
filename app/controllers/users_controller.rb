#coding:utf-8
require 'util.rb'
require 'open-uri'
require 'net/http'
require 'slack-notifier'
require 'json'

class UsersController < ApplicationController
  before_filter :init, :authenticate_user, :except => [:login, :login_complete, :logout, :invite, :invite_complete, :give_points_slack, :give_points_slack_response, :forgot_password, :forgot_password_submit, :fb_auth]
  before_filter :init_url
  before_action :timeline_message, :only => [:index, :profile, :given, :timeline]
  before_action :belonging_team, :only => [:index, :profile, :given, :timeline, :articles]

  def init
    if session[:id].present? || cookies[:id].present?
      @id = session[:id] || cookies[:id]
      user = User.find(@id)

      @company_id = user.company_id
      @admin_flag = Company.exists?(:email => user.email) ? 1 : 0
    end

    #if give_points_slack was accessed
    if params[:code].present?
      slack_code = params[:code]

      data = {
      	:client_id	=> "12258104198.88079493873",
      	:client_secret	=> "d3cc97422eac0aefbf7c097a3647306c",
      	:code		=> params[:code]
      }

      uri	= URI.parse("https://slack.com/api/oauth.access")
      http	= Net::HTTP.post_form(uri, data)
      userinfo	= JSON.parse(http.body)

      slack	= SlackToken.where(:team_id => userinfo["team_id"]).first
      
      if slack.blank?
      	slack = SlackToken.new

      	slack.token	    = userinfo["access_token"]
      	slack.team_id	    = userinfo["team_id"]
      	slack.webhooks_url  = userinfo["incoming_webhook"]["url"]
      	slack.bot_token	    = userinfo["bot"]["bot_access_token"]
      	slack.save
      else
      	slack.token	    = userinfo["access_token"]
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
      	  cookies.permanent[:id]    = authorized_user.id
      	  cookies.permanent[:email] = authorized_user.email
      	else
      	  session[:id]	  = authorized_user.id
      	  session[:email] = authorized_user.email
      	end

      	verified = authorized_user.verified
      	flash[:notice] = "" 

      	if verified == 0
      	  redirect_page("users", "update")
      	else
          if $use_timeline.include?(authorized_user.company_id)
            redirect_page("users", "timeline")
          else
      	    redirect_page("users", "index")
          end
      	end
      end
    else
      flash[:notice] = "ユーザー名かパスワードに誤りがあります"
      render 'login', :status => :unauthorized
    end
  end

  def logout
    session[:id]    = nil
    session[:email] = nil

    cookies.delete :id
    cookies.delete :email
    
    reset_session

    redirect_page("users", "login")
  end

  def index
    # $showoff_timeline
    if $showoff_timeline.include?(@company_id)
      redirect_page("users", "profile")
      return
    end

    today = Date.today
    hashtags = Company.find(@company_id).hashtags
    if hashtags.blank?
      @hashtags = ["leadership","hardwork","creativity","positivity","teamwork"] 
    else
      @hashtags = hashtags.split(",")
    end

    @user     = User.find(@id)
    @users    = User.where(:company_id => @company_id, :delete_flag => 0) 
    @company = Company.find(@company_id)
    @emails = []
    @users.each do |user|
      @emails << user.email
    end
    if @company.point_fixed_flag == 0
      @placeholder = "+5 会議の資料作成ありがとう！急なお願いだったのに迅速な対応におどろき！#speed #資料良かった #いつのまにかパワポスキルあがってる"
    else
      @placeholder = "会議の資料作成ありがとう！急なお願いだったのに迅速な対応におどろき！#speed #資料良かった #いつのまにかパワポスキルあがってる"
    end
    # team_users for getName
    get_team_users
    # team_users = []
    # same_teams = []
    # Team.where(company_id: @company_id, manager_id: @id, delete_flag: 0).each do |team|
    #   same_teams << team
    # end
    # Team.where(company_id: @company_id, delete_flag: 0).each do |team|
    #   if team.member_ids.split(",").include?(@id)
    #     same_teams << team
    #   end
    # end
    # same_teams.each do |team|
    #   team_users.push(team.member_ids.split(",")).flatten!
    #   team_users.push(team.manager_id.to_s).flatten!
    # end
    # team_users.uniq!
    # @team_users = []
    # team_users.each do |user|
    #   unless user.to_i == 0
    #   @team_users << User.find(user.to_i)
    #   end
    # end
    # end of team_users for getName
    @bonuses  = Bonus.where(:company_id => @company_id, :delete_flag => 0) 

    # birthday user today
    @birthday_users = @users.where('MONTH(birthday)=? AND DAYOFMONTH(birthday)=?', today.month, today.day).where(delete_flag: 0)

    # upcoming birthday
    range_time	= today.mday..today.end_of_month.mday
    b_users	= @users.where('MONTH(birthday) = ?', today.month).where(delete_flag: 0)
    @b_users = []
    b_users.each do |bu|
      if range_time.cover?(bu.birthday.mday)
        @b_users << bu
      end
    end
    
    # definition for pnotify 
    @default_birthday = "2016-01-01"
    posts	= Post.where(:company_id => @company_id, :privacy => 0, :delete_flag => 0)
    bonus_posts = Post.where(:company_id => @company_id, :privacy => 1, :delete_flag => 0).where("receiver_id = #{@user.id} OR user_id = #{@user.id}")

    all_posts	= ((posts + bonus_posts).sort_by &:update_time).reverse
    posts_count = all_posts.count

    limit = 10
    page = params[:page] || 1
    
    @total_items = posts_count
    @total_pages = (@total_items/limit.to_f).ceil

    if page.to_i <= 1
      page    = 1
      offset  = 0
    else
      offset  = (page.to_i * limit) - limit
    end

    all_posts = all_posts[offset, limit]
    posts     = Post.where(id: all_posts.map(&:id)).order("update_time desc")

    @page_now = params[:page].to_i
    
    if @page_now == 0
      @page_now = 1
    end
    
    @previous_page  = @page_now - 1
    @next_page	    = @page_now + 1

    @posts  = []
    data    = {}

    posts.each do | post |
      data = process_post(post)
      @posts << data
    end

    top_givers = Post.where(company_id: @company_id, delete_flag: 0).group(:user_id).order("count_all desc").limit(5).count
    process_top_givers(top_givers)

    top_receivers = Post.where(company_id: @company_id, delete_flag: 0).group(:receiver_id).order("count_all desc").limit(5).count
    process_top_receivers(top_receivers)
    @top_hashtags = Hashtag.where(company_id: @company_id, delete_flag: 0).group(:hashtag).order("count_id desc").limit(7).count("id")

    @num_rewards  = Reward.where(company_id: @company_id, delete_flag: 0).count
    @num_bonus	  = Bonus.where(company_id: @company_id, delete_flag: 0).count

    @popular_rewards = []
    
    if @user.company.plan > 0
      rewards_list = RequestReward.where(company_id: @company_id, delete_flag: 0).group(:rewards_prizy_id).order("count_id desc").count("id")
      
      if rewards_list.present?
        rewards_list.each do |key, value|
	        @popular_rewards << RewardsPrizy.find(key) if key.present?
        end
        
	      @popular_rewards = RewardsPrizy.all if @popular_rewards.blank?
      else
        @popular_rewards = RewardsPrizy.all
      end
    else
      rewards_list = RequestReward.where(company_id: @company_id, delete_flag: 0).group(:reward_id).order("count_id desc").count("id")
      
      rewards_list.each do |key, value|
        @popular_rewards << Reward.find(key)
      end
    end

    receiver_ranking(@user)
    giver_ranking(@user)
  end

  def give_recog_by_email
    @addeduser = User.find_by(company_id: @company_id,delete_flag: 0, email: params[:email])
    render :json => {:id => @addeduser.id , :name => @addeduser.name }
  end

  def give_points_slack
    slack = SlackToken.where(:team_id => params["team_id"]).first
    
    @slack_token    = slack[:token]
    @slack_webhooks = slack[:webhooks_url]

    slack_user_info_data = {
      user:  params["user_id"],
      token: @slack_token,
    }

    slack_user_list_data = {
      token:    @slack_token,
      presence: 1,
    }

    uri	      = URI.parse("https://slack.com/api/users.info")
    http      = Net::HTTP.post_form(uri, slack_user_info_data)
    userinfo  = JSON.parse(http.body)

    uri	      = URI.parse("https://slack.com/api/users.list")
    http      = Net::HTTP.post_form(uri, slack_user_list_data)
    userlist  = JSON.parse(http.body)

    begin
      email = userinfo["user"]["profile"]["email"]
      error = 0

      user  = User.find_by_email(email)

      unless user.blank?
      	params[:user_id]      = user.id 
      	params[:company_id]   = user.company_id
      	params[:description]  = params["text"]

      	receiver_name = params["text"].scan(/\@[^\s|　]+/).first.gsub("@","")
      	receiver      = ""

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
            @company = Company.find(user.company_id)
      	    if @company.point_fixed_flag == 0
              points = params["text"].scan(/\+[^\s|　]+/).first.gsub("+","").to_i
            else
              points = @company.fixed_point
            end

      	    params[:points]	  = points
      	    params[:receiver_id]  = receiver.id

      	    if (points <= user[:out_points])
      	      user.out_points -= params[:points]
      	      user.save

      	      hashtags = params["text"].scan(/\#[^\s|　]+/)
      	      receiver.in_points += params[:points]
      	      receiver.save

       	      UserMailer.receive_points_email({
        		    receiver:   receiver.name, 
        		    email:	    receiver.email,
        		    giver:	    user.name,
        		    points:	    params[:points],
        		    prizy_url:  @prizy_url + "/user"
      	      }).deliver_later

      	      post = Post.new
      	      post.save_record(params)
      	      params[:post_id] = post.id

      	      hashtags.each do | tag |
      		    params[:hashtag] = tag 
      		    hashtag = Hashtag.new
      		    hashtag.save_record(params)
      	      end

          		user.badge += 1 if (user.badge).present?
          		user.save

              ios_push_notif(receiver.id,"#{user.firstname}さんから「ホメ」が届きました。", user.badge)

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
      	team_domain	= params["team_domain"].upcase
      	flash[:notice]	= "Your email #{email} is not yet registered to #{team_domain} Prizy"
      end
    rescue Exception => e
      if @company.point_fixed_flag == 0
      flash[:notice] = "投稿できませんでした。入力に不備があります。\n （入力例)\n「/prizy +20 @tanaka.naoki 会議の資料つくってくれてありがとう。グラフィックの出来が半端なかった！！#急成長 #デザインセンス抜群 #またお願いするわww」"
      else
        flash[:notice] = "投稿できませんでした。入力に不備があります。\n （入力例)\n「/prizy @tanaka.naoki 会議の資料つくってくれてありがとう。グラフィックの出来が半端なかった！！#急成長 #デザインセンス抜群 #またお願いするわww」"
      end
    end

    render :layout => false
  end

  def give_points
    new_posts = params[:new_post]
    nickname_id = params[:nickname_id].to_i if params[:nickname_id]

    new_posts.each do |post|
      if post[:receiver_id].present?
        post[:receiver_id] = post[:receiver_id].uniq
        post[:receiver_id].each do |r|
          if r == @id
            flash[:status] = "false"
            flash[:notice] = "自分にポイントを贈ることはできません。"
            @description = params[:description]
            error = 1
          else
            post[:receiver_id] = r
            parse_points(post, nickname_id)
          end
        end
      else
        flash[:status] = "false"
        flash[:result] = "送信に失敗しました。"
        flash[:notice] = "「名前からメッセージを贈る相手を探す」場合は、社員名をクリックしてから「追加」ボタンを押してください"
        @description = params[:description]
        error = 1
      end
    end
    redirect_to controller: "users", action: "given", description: @description
  end

  def parse_points(params, nickname_id)
    params[:nickname_id] = nickname_id if nickname_id
    @company = Company.find(@company_id)
    @users  = User.where(:company_id => @company_id, :delete_flag => 0) 
    @user   = User.find(@id)
    @teams = Team.of_company(@company_id).available
    belonging = nil
    @teams.map { |team| belonging = team if team.member_ids.present? && team.member_ids.split(",").include?(@user.id.to_s) }
    error   = 0

    if @company.point_fixed_flag == 0
      points = params[:description].scan(/\+[^\s|　]+/).first.to_i
    else
      points = @company.fixed_point
    end
    params[:user_id]	= @id
    params[:company_id] = @company_id
    params[:points]	= points

    if (params[:receiver_id].present?)
      if params[:receiver_id].include?(@id)
        flash[:status] = "false"
	      flash[:notice] = "自分にポイントを贈ることはできません。"
        @description = params[:description]
	      error = 1
      elsif params[:description].length > 1024
        flash[:status] = "false"
        flash[:notice] = "メッセージは1024文字以下にしてください"
        @description = params[:description]
        error = 1
      elsif params[:receiver_id].nil?
        flash[:status] = "false"
        flash[:result] = "送信に失敗しました。"
        flash[:notice] = "「名前からメッセージを贈る相手を探す」場合は、社員名をクリックしてから「追加」ボタンを押してください"
        @description = params[:description]
        error = 1
      end

      if error == 0
        receiver_ids  = params[:receiver_id]
        # receiver_count  = receiver_ids.count
        # points		= points * receiver_count
        points		= points * 1

	      params[:receiver_id] = receiver_ids

	      if (points <= @user[:out_points])
	        @user.out_points -= points
	        @user.save

	        unless params[:type] == "comment"
	          post = Post.new
	          post.save_record(params)
	          params[:post_id] = post.id
	        end

    	    receiver_ids.split(",").each do | receiver_id |
	          receiver = User.find(receiver_id.to_i)

            if @company.give_point_to_sender_and_receiver_flag == 0
              if @company.send_point_for_not_received_flag == 1 && receiver.in_points == 0
                @user.in_points += @company.send_point_for_not_received
              end
            elsif @company.give_point_to_sender_and_receiver_flag == 1
              if @company.send_point_for_not_received_flag == 1 && receiver.in_points == 0
                @user.in_points += @company.send_point_for_not_received
                @company.bonus_points -= @company.send_point_for_not_received
              else
                @user.in_points += @company.send_point
                @company.bonus_points -= @company.send_point
              end
            end
            @company.save
            @user.save

	          receiver.in_points += params[:points]
	          receiver.save

    	      unless params[:type] == "comment"
	            UserMailer.receive_points_email({
                sender: "#{@user.try(:lastname)}" "#{@user.try(:firstname)}",
                sender_belonging: "#{belonging.try(:team_name)}",
                nickname_id: params[:nickname_id], 
                receiver: "#{receiver.try(:lastname)}" "#{receiver.try(:firstname)}" , 
            	  email:	    receiver.email,
        	      giver:	    @user.name,
        	      points:	    params[:points],
                description: params[:description],
          	    prizy_url:  @prizy_url + "/user"
              }).deliver_later
	          end

        		p @user
        		if @user[:badge].present?
        		  @user.badge += 1
        		  @user.save
        		end
            flash[:notice] = "送信が完了しました。"
  	        # ios_push_notif(receiver.id, "#{@user.firstname}さんから「ホメ」が届きました。", @user.badge)
	        end
        else
          flash[:status] = "false"
          flash[:notice] = "ポイントが足りません"
          @description = params[:description]
        end
      else
        flash[:status] = "false"
        @description = params[:description]
      end
    else
      flash[:status] = "false"
      @description = params[:description]
      flash[:notice] = "送信に失敗しました。送信相手を選択してください。"
    end
    # rescue => e
    # flash[:notice] = "#{e}"
  end

  def give_comments
    @company = Company.find(@company_id)
    params[:company_id] = @company_id
    params[:user_id]	= @id

    #params[:description]  = simple_format(params["comments"])
    params[:description]  = params["comments"].gsub(/\n/, '<br>')
    params[:points]    = params["comments"].scan(/\+[^\s|　]+/).first
    params[:type]   = "comment"

    params["comments"]  = params["comments"].gsub(/\n/, '<br>')

    if params[:description].length > 2000
      flash[:notice] = "コメントは2000文字以内です"
    else
      res = Comment.new
      res.save_record(params)

      user = User.find(@id)

      if user.badge.present?
        user.badge += 1
        user.save
      end

      #send email to the one who wrote the message
      #somebody commented on the post
      receiver_ids = []
      post_user_id = Post.find(params[:post_id]).user_id
      post_receiver_ids = Post.find(params[:post_id]).receiver_id
      post_receiver_ids = post_receiver_ids.split(",") if post_receiver_ids.present?

      receiver_ids << post_user_id
      post_receiver_ids.each do | post_receiver_id |
        receiver_ids << post_receiver_id.to_i
      end

      receiver_ids.each do |receiver_id|
        if receiver_id != @id.to_i
          receiver = User.find(receiver_id)
          send_emails("comments",receiver,params[:description])
        end
      end

      #ios_push_notif(params[:receiver_id], "#{user.firstname}さんがコメントしました。", user.badge)

      redirect_page("users", "index")
    end
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

      receiver_ids = []
      post_user_id = Post.find(params[:post_id]).user_id
      post_receiver_ids = Post.find(params[:post_id]).receiver_id
      post_receiver_ids = post_receiver_ids.split(",") if post_receiver_ids.present?

      receiver_ids << post_user_id
      post_receiver_ids.each do | post_receiver_id |
        receiver_ids << post_receiver_id.to_i
      end

      receiver_ids.each do |receiver_id|
        if receiver_id != @id.to_i
          receiver = User.find(receiver_id)
          send_emails("likes",receiver,params[:description])
        end
      end
    end

    # redirect_to "/user"
    redirect_page("users", "index")
  end

  def send_emails(type, receiver, description)
    belonging = nil
    post = Post.find(params[:post_id])
    @company = Company.find(@company_id)
    @user   = User.find(@id)
    @teams = Team.of_company(@company_id).available
    @teams.map { |team| belonging = team if team.member_ids.present? && team.member_ids.split(",").include?(@user.id.to_s) }

    data = {
      post_sender_id: post.user_id,
      sender_id: @user.id,
      sender: "#{@user.try(:lastname)}" "#{@user.try(:firstname)}",
      sender_belonging: "#{belonging.try(:team_name)}",
      nickname_id: post.nickname_id.to_i,
      receiver: "#{receiver.try(:lastname)}" "#{receiver.try(:firstname)}" , 
      email: receiver.try(:email),
      giver: @user.try(:name),
      description: description,
      prizy_url: @prizy_url + "/profile"
    }

    if type == "comments"
      UserMailer.receive_comments_email(data).deliver_later
    elsif type == "likes"
      UserMailer.receive_likes_email(data).deliver_later
    elsif type == "comments2"
      UserMailer.comment_on_comment_email(data).deliver_later
    end

  end

  def ios_push_notif(id, message, badge)
    devices = IosToken.where(:user_id => id)
    unless devices.present?
      return
    else
      devices.each do | device |
=begin      
	sns_message = {
	  'default'=> message,
	  'message'=> {
	    'APNS_SANDBOX'=> {
	      'aps'=> {
		'alert'=> 'inner message',
		'badge'=> badge,
		'category' => "GENERAL"
	      }
	    }
	  }
	}
=end
	apns_body = {
	  'aps' => {
	    'alert' =>  message,
	    'badge' =>  badge.to_i,
	    'category' => "GENERAL"
	  }
	}.to_json

	sns_message = {
	  'default' => message,
	  'APNS' => apns_body 
	}

	sns = Aws::SNS::Client.new
	sns.publish(
	  target_arn: device.arn, 
	  message: sns_message.to_json, 
	  message_structure: "json"
	)

      end
    end
  end

  def select_target_department
    @teams = Team.of_company(@company_id).available.where(department_id: params[:id]).order(sort: :asc)
    @targets = []
    @teams.each do |team|
      @targets << [team.id, team.team_name]
    end
    render :json => @targets
  end

  def select_target_team
    @team = Team.find(params[:id])
    @targets = []
    unless @team.manager_id == 0
      @manager = User.find_by(id: @team.manager_id, delete_flag: 0)
      unless @manger.nil? 
        if @manager.lastname.nil? || @manager.firstname.nil?
          @manager_name = @manager.name
        else
          @manager_name = @manager.lastname + @manager.firstname
        end
        @targets << [@manager.id, @manager_name]
      end
    end

    @team.member_ids.split(",").each do |id|
      @user = User.find_by(id: id.to_i, delete_flag: 0)
      unless @user.nil?
        if @user.lastname.nil? || @user.firstname.nil?
          @user_name = @user.name
        else
          @user_name = @user.lastname + @user.firstname
        end
        @targets << [@user.id, @user_name]
      end
    end
    render :json => @targets
  end

  def profile
    @user = User.find(@id)
    @users    = User.available.of_company(@company_id)
    @departments = Department.available.of_company(@company_id).order(sort: :asc)
    @banner = Banner.find_by(company_id: @company_id, is_deleted: 0)
    @user_ids, @user_fullnames  = User.autocomplete_suggestions(@company_id)
    @total_receive_message = Post.where(company_id: @company_id, delete_flag: 0, receiver_id: @user.id).count
    @user_posted_contents = Article.where(company_id: @company_id, is_casual: 1, is_deleted: 0, is_published: 1).order(created_at: :desc).limit(5)

    @company = Company.find(@user.company_id)
    if $showoff_timeline.include?(@company_id)
      unless $use_select.include?(@company_id)
        get_team_users
      end
      # @emails = []
      # @users.each do |user|
      #   @emails << user.email
      # end
      hashtags = @company.hashtags
      if hashtags.blank?
        @hashtags = ["leadership","hardwork","creativity","positivity","teamwork"] 
      else
        @hashtags = hashtags.split(",")
      end
    end
    # weekly_ranking
    receiver_ranking(@user)
    giver_ranking(@user)


    # posts = Post.where(:receiver_id => @id, :delete_flag => 0).order("update_time desc")
    posts = Post.where(:delete_flag => 0, company_id: @company.id).where("receiver_id like '%" + @id + "%'").order("update_time desc")

    process_posts = process_paging(posts)

    @posts = []
    data = {}

    process_posts.each do | post |
      data = process_post(post)
      @posts << data
    end

    user_posts = @user_posted_contents
    @first_images = {}
    
    user_posts.each do | post |
      set_first_image(post)
    end 

  end

  def timeline
    @user = User.find(@id)
    @users    = User.where(:company_id => @company_id, :delete_flag => 0) 
    @departments = Department.where(company_id: @company_id, delete_flag: 0).order(sort: :asc)
    @banner = Banner.find_by(company_id: @company_id, is_deleted: 0)
    @user_ids, @user_fullnames  = User.autocomplete_suggestions(@company_id)
    @total_receive_message = Post.where(company_id: @company_id, delete_flag: 0, receiver_id: @user.id).count
    @user_posted_contents = Article.where(company_id: @company_id, is_casual: 1, is_deleted: 0, is_published: 1).order(updated_at: :desc)

    @company = Company.find(@user.company_id)
    # weekly_ranking
    receiver_ranking(@user)
    giver_ranking(@user)

    posts = Post.where(company_id: @company_id ,delete_flag: 0).order("update_time desc")
    process_posts = process_paging(posts)

    @posts = []
    data = {}

    process_posts.each do | post |
      data = process_post(post)
      @posts << data
    end

    user_posts = @user_posted_contents
    @first_images = {}
    
    user_posts.each do | post |
      set_first_image(post)
    end 
  end

  def articles
    @user = User.find(@id)
    @users    = User.where(:company_id => @company_id, :delete_flag => 0) 
    @departments = Department.where(company_id: @company_id, delete_flag: 0).order(sort: :asc)
    @banner = Banner.find_by(company_id: @company_id, is_deleted: 0)
    @user_posted_contents = Article.where(company_id: @company_id, is_published:1, is_casual: 1, is_deleted: 0).order(created_at: :desc).limit(5)
    @user_ids, @user_fullnames  = User.autocomplete_suggestions(@company_id)
    @total_receive_message = Post.where(company_id: @company_id, delete_flag: 0, receiver_id: @user.id).count

    @company = Company.find(@user.company_id)
    # weekly_ranking
    receiver_ranking(@user)
    giver_ranking(@user)

    # paging
    articles = Article.where(company_id: @company_id, is_deleted: 0, is_published: 1, is_casual: 0).order(created_at: :desc)
    process_posts = process_paging_articles(articles)    
    @articles = []

    @first_images = {}

    process_posts.each do | post |
      set_first_image(post)
      @articles << post
    end

    user_posts = @user_posted_contents
    user_posts.each do | post |
      set_first_image(post)
    end 
  end

  def given
    @user = User.find(@id)
    @users    = User.where(company_id: @company_id, :delete_flag => 0) 
    @departments = Department.where(company_id: @company_id, delete_flag: 0).order(sort: :asc)
    @company = Company.find(@user.company_id)
    @banner = Banner.find_by(company_id: @company_id, is_deleted: 0)
    @user_ids, @user_fullnames  = User.autocomplete_suggestions(@company_id)
    @total_receive_message = Post.where(company_id: @company_id, delete_flag: 0, receiver_id: @user.id).count
    @user_posted_contents = Article.where(company_id: @company_id, is_casual: 1, is_deleted: 0, is_published: 1).order(created_at: :desc).limit(5)

    @description = params[:description] if params[:description]

    receiver_ranking(@user)
    giver_ranking(@user)
    posts = Post.where(:user_id => @id, :delete_flag => 0).order("update_time desc")
    process_posts = process_paging(posts)

    @posts = []
    data = {}
    @send_to_user = User.of_company(@company_id).find(params[:user_id]) if params[:user_id].present?
    process_posts.each do |post|
      data = process_post(post)
      @posts << data
    end
    # top_givers = Post.where(user_id: @id, delete_flag: 0).group(:receiver_id).order("count_all desc").limit(5).count
    # process_top_givers(top_givers)
    # @top_hashtags = Hashtag.where(user_id: @id, delete_flag: 0).group(:hashtag).order("count_id desc").limit(7).count("id")

    user_posts = @user_posted_contents
    @first_images = {}
    
    user_posts.each do | post |
      set_first_image(post)
    end 
  end

  def set_first_image(post)
    image = post.images.order("is_eye_catch desc, place_number asc").first
      
    @first_images[post.id] = ""
    if image.present?
      @first_images[post.id] = image[:img_src]
    end
  end

  def get_team_users
    team_users = []
    same_teams = []
    Team.where(company_id: @company_id, manager_id: @id, delete_flag: 0).each do |team|
      same_teams << team
    end
    Team.where(company_id: @company_id, delete_flag: 0).each do |team|
      if team.member_ids.split(",").include?(@id)
        same_teams << team
      end
    end
    same_teams.each do |team|
      team_users.push(team.member_ids.split(",")).flatten!
      team_users.push(team.manager_id.to_s).flatten!
    end
    team_users.uniq!
    @team_users = []
    team_users.each do |user|
      unless user.to_i == 0
      @team_users << User.find(user.to_i)
      end
    end
  end

  def receiver_ranking(user)
    last_week =  Date.today.prev_week.beginning_of_week...Date.today.beginning_of_week
    this_week = Date.today.beginning_of_week...Date.today.next_week.beginning_of_week
    
    @receiver_ratio = []
    @this_week_posts = Post.where(company_id: @company_id, delete_flag: 0, receiver_id: user.id, create_time: this_week).count
    @receiver_ratio << @this_week_posts

    if this_week.cover?(user.create_time)
      @receiver_ratio << "-"
    else
      @last_week_posts = Post.where(company_id: @company_id, delete_flag: 0, receiver_id: user.id, create_time: last_week).count
      @last_week_posts = 1 if @last_week_posts == 0
      @receiver_ratio << (@this_week_posts.to_f / @last_week_posts.to_f) * 100
      return @receiver_ratio
    end
  end

  def giver_ranking(user)
    last_week = Date.today.prev_week.beginning_of_week...Date.today.beginning_of_week
    this_week = Date.today.beginning_of_week...Date.today.next_week.beginning_of_week

    @giver_ratio =[]
    @this_week_posts = Post.where(company_id: @company_id, delete_flag: 0, user_id: user.id, create_time: this_week).count
    @giver_ratio << @this_week_posts

    if this_week.cover?(user.create_time)
      @giver_ratio << "-"
    else
      @last_week_posts = Post.where(company_id: @company_id, delete_flag: 0, user_id: user.id, create_time: last_week).count
      @last_week_posts = 1 if @last_week_posts == 0
      @giver_ratio << (@this_week_posts.to_f / @last_week_posts.to_f) * 100
      return @giver_ratio
    end
  end

  def process_paging(posts)
    limit = 10
    page  = params[:page] || 1
    
    @total_items = posts.count
    @total_pages = (@total_items/limit.to_f).ceil

    if page.to_i <= 1
      page    = 1
      offset  = 0
    else
      offset = (page.to_i * limit) - limit
    end

    posts = posts.offset(offset).limit(limit)

    @page_now = params[:page].to_i
    
    if @page_now == 0
      @page_now = 1
    end

    @previous_page  = @page_now - 1
    @next_page	    = @page_now + 1
    return posts
  end

  def process_paging_articles(posts)
    limit = 6
    page  = params[:page] || 1
    
    @total_items = posts.count
    @total_pages = (@total_items/limit.to_f).ceil

    if page.to_i <= 1
      page    = 1
      offset  = 0
    else
      offset = (page.to_i * limit) - limit
    end

    posts = posts.offset(offset).limit(limit)

    @page_now = params[:page].to_i
    
    if @page_now == 0
      @page_now = 1
    end

    @previous_page  = @page_now - 1
    @next_page      = @page_now + 1
    return posts
  end

  def process_top_receivers(top_receivers)
    @top_receivers = []
    top_receivers.each do | k, v |
      user = User.find(k)
      data = { name: "#{user.lastname} #{user.firstname}", img_src: user.img_src, count: v }
      @top_receivers << data
    end
  end

  def process_top_givers(top_givers)
    @top_givers = []
    
    top_givers.each do | k, v |
      user = User.find(k)
      data = { name: user.name, img_src: user.img_src, count: v }
      @top_givers << data
    end
  end

  def process_post(post)
    comments  = Comment.where(:post_id => post.id, :delete_flag => 0)
    kudos     = Kudos.where(:post_id => post.id, :kudos => 1, :delete_flag => 0)

    # if post.receiver_id.include?(",")
    #   post.receiver_id = post.receiver_id.delete(",")
    # end

    data = {
      id:		  post.id,
      user_id:		  post.user_id,
      belonging_team: "#{@belonging_team[post.user_id].try(:department).try(:dep_name)}  #{@belonging_team[post.user_id].try(:team_name)} ",
      nickname: $nicknames[post.nickname_id],
      user_name:	  post.user.name,
      full_user_name:	  "#{post.user.lastname}#{post.user.firstname}",
      receiver_id:	  [],
      receiver_name:	  [],
      full_receiver_name: [],
      receiver_belonging_user_team: [],
      # receiver_img:	  post.receiver.img_src,
      user_img:		  post.user.img_src,
      points:		  post.points,
      description:	  post.description,
      hashtags:		  post.hashtags,
      comments:		  comments,
      kudos:		  kudos,
      create_time:	  post.create_time.strftime("%Y/%m/%d %H:%M:%S")
    }

    receiver_ids = []
    if post.receiver_id.present?
      receiver_ids = post.receiver_id.split(",")
      receiver_ids.each do | r |
        if r.present?
          receiver_info = User.find(r)
          data[:receiver_id]  << r
          data[:receiver_name]  << receiver_info.name
          data[:full_receiver_name] << "#{receiver_info.lastname}#{receiver_info.firstname}"
          # data[:receiver_belonging_user_team] << "#{@belonging_team[post.user_id].try(:department).try(:dep_name)} / #{@belonging_team[post.user_id].try(:team_name)} #{receiver_info.lastname}#{receiver_info.firstname}"
        end
      end
    end

    return data
  end

  def rewards
    @user	    = User.find(@id)
    @rewards	    = Reward.where(:company_id => @user.company_id, :delete_flag => 0).order("points").order("title")
    @rewards_prizy  = RewardsPrizy.where(:delete_flag => 0)
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
        :reward   => res.rewards_prizy.title,
        :points   => res.rewards_prizy.points,
        :username => user.name,
        :email    => user.email,
        :company  => user.company.name
      }

      UserMailer.redeem_prizy_reward(reward_data).deliver_later
    else
      points = res.reward.points
    end

    user.in_points -= points 
    user.save

    data[:username]   = user.name
    data[:owner]      = user.company.owner
    data[:email]      = user.company.email
    data[:prizy_url]  = @prizy_url + "/company/rewards/request#pending"

    CompanyMailer.request_reward_email(data).deliver_later
    redirect_page("users","rewards")
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

    redirect_page("users","rewards_status")
  end

  def update 
    session[:redirect] = nil
    update_details

    @user = User.find(@id)
    @departments = Department.of_company(@user.company_id).available
    @teams = Team.of_company(@user.company_id).available
    @teams.each do |team|
      if team.member_ids.present? && team.member_ids.split(",").include?(@user.id.to_s)
        @team = team
      end
    end
  end

  def invite
    session[:redirect] = nil
    $c_code = params[:c_code] if params[:c_code].present?

    if $c_code.present?
      invite_link = InviteLink.where(c_code: $c_code, delete_flag: 0)

      unless invite_link.empty?
        update_details
        company       = Company.find(invite_link[0][:company_id])
        @company_name = company.name
        @company_id   = company.id
        @departments = Department.where(company_id: @company_id, delete_flag: 0).order(sort: :asc)
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
    url	    = "https://graph.facebook.com/#{fb_user['id']}/picture?width=300&height=300"
    res	    = Net::HTTP.get_response(URI(url))
    fb_pic  = res['location']
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
    params[:name] = params[:lastname] + params[:firstname]
    update_complete_details

    # add_team
    team_id = params[:team_id]
    team = Team.find(team_id)
    if team
      user = User.find_by(email: params[:email])
      team.member_ids = team.member_ids + "," + user.id.to_s
      team.save
    end

    if session[:redirect].nil?
      data = {
        :email    => params[:email],
        :name     => params[:name],
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
    password_short = "設定に失敗しました。パスワードは4文字以上にしてください。"
    name_exist = "そのユーザー名はすでに使われております。"
    email_exist = "そのメールアドレスはすでに使われております。"
    session[:redirect] = nil

    url = request.original_url
    verified = 0

    unless url.include?("invite")
      username_exist = User.where(name: params[:name]).of_company(@company_id).available
      teams = Team.of_company(@company_id).available

      res	= User.find(@id)
      verified	= res.verified

      teams.each do |lastteam|
        if lastteam.member_ids && lastteam.member_ids.include?(',') && lastteam.member_ids.include?(res.id.to_s)
          test = [res.id.to_s]
          lastteam.member_ids = (lastteam.member_ids.split(",") - (test)).join(",")
        elsif lastteam.member_ids && lastteam.member_ids.include?(res.id.to_s)
          lastteam.member_ids = lastteam.member_ids.delete(res.id.to_s)
        end
        lastteam.save
      end
      next_team = Team.available.of_company(@company_id).find(params[:team_id])
      if next_team.member_ids.present? && next_team.member_ids.length > 0
        next_team.member_ids = next_team.member_ids + ',' + res.id.to_s
      else
        next_team.member_ids = res.id.to_s
      end
      next_team.save

      unless res.name == params[:name]
        if params[:password].present? && params[:password].length < 4
          flash[:notice]      = password_short 
          session[:redirect]  = 1

          redirect_to "/update" and return
      	end
      end
    else
      username_exist = User.where(name: params[:name], company_id: params[:company_id])
      if username_exist.present?
      	flash[:notice]	    = name_exist 
      	session[:redirect]  = 1

      	redirect_to "/invite" and return
      end

      useremail_exist = User.where(email: params[:email], company_id: params[:company_id])
      if useremail_exist.present?
        flash[:notice]      = email_exist 
        session[:redirect]  = 1
        redirect_to "/invite" and return
      end


      res = User.new
      res.save_record(params)
    end

    if params[:b_year] && params[:b_month] && params[:b_day]
      b_year  = params[:b_year]
      b_month = params[:b_month]
      b_day   = params[:b_day]
      params[:birthday] = DateTime.parse("#{b_year}-#{b_month}-#{b_day}").strftime("%Y-%m-%d") 
    end

    if params[:img_src].present?
      unless params[:fb_data].to_i == 1
      	src	  = params[:img_src]
      	src_ext	  = File.extname(src.original_filename)

      	s3  = Aws::S3::Resource.new
      	obj = s3 .bucket(@s3_bucket).object("profile/user_#{res.id}_pic#{src_ext}")
      	
       	obj.upload_file src.tempfile, {acl: 'public-read'}

      	params[:img_src] = obj.public_url
      end
    else
      if verified == 0
      	params[:img_src] = "https://#{@s3_bucket}.s3-ap-northeast-1.amazonaws.com/common/noimg_pc.png" 
      end
    end

    params[:out_points] = 100000 if verified == 0
    params[:verified] = 1 
      
    if url.include?("invite")
      res.img_src     = params[:img_src]
      res.out_points  = params[:out_points]
      res.verified    = params[:verified]
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
      	:email	    => params[:email],
      	:password   => temp_password,
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
      	  sender: "#{@user.try(:firstname)}" "#{@user.try(:lastname)}",
          receiver: "#{receiver.try(:firstname)}" "#{receiver.try(:lastname)}" , 
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
    post_id = params[:post_id]
    post      = Post.where(id: post_id).where("(user_id = ?) OR (receiver_id = ?)", @id, @id).update_all(delete_flag: 1)
    comments  = Comment.where(post_id: post_id).where("(user_id = ?) OR (receiver_id = ?)", @id, @id).update_all(delete_flag: 1)
    kudos     = Kudos.where(post_id: post_id).where("(user_id = ?) OR (receiver_id = ?)", @id, @id).update_all(delete_flag: 1)
    # hashtags  = Hashtag.where(post_id: post_id).where("(user_id = ?) OR (receiver_id = ?)", @id, @id).update_all(delete_flag: 1)

    redirect_page(params[:before_controller], params[:before_action])
  end

  def redirect_to_index
    redirect_to "/user" 
  end

  def timeline_message
    @random_messages = ["素敵なありがとうが贈られました。", "日頃の感謝を伝えてみましょう", "感謝の心が人を育て、感謝の心が自分を磨く", "感謝の数だけ強くなれる！？", "ありがとうの一言が周りを明るくする"]
  end
end
