class AnalyticsController < ApplicationController

  before_filter :init, :authenticate_user
  before_action :ip_address_limit
  before_filter :init_url, :validate_user
  before_action :time_definition, only:[:overall, :index, :giver, :hashtag, :hashtagpoints, :allhashtag, :allhashtagpoints, :user, :userpoints]
  before_action :basic_info, only:[:overall, :index, :giver, :hashtag, :hashtagpoints, :allhashtag, :allhashtagpoints, :user, :userpoints]
  before_filter :analytics_init, only:[:userreceived, :usergiven]
  before_action :restrict_access_by_smartphone

  def init
    if session[:email].present? || cookies[:email].present?
      email = session[:email] || cookies[:email]
      user = User.find_by_email(email)
      if user.admin == 1
	@id = user.company_id
	@user_id = user.id
      else
        redirect_to "/user"
      end

    else
      logout
    end
  end

  def logout
    session[:id] = nil
    session[:email] = nil
    cookies.delete :id
    cookies.delete :email
    reset_session

    redirect_to '/login'
  end

  def overall
    @hash = {}
    @points = {}
    @time_custom.each do |time|
      @a = time..time.tomorrow
      @post = Post.where(company_id: @id, create_time: @a, delete_flag: 0).count
      @point = Post.where(company_id: @id, create_time: @a, delete_flag: 0).sum(:points)
      @hash[time] = @post
      @points[time] = @point
    end
  end

  def index
    @hash = {}
    @points = {}
    @posts = Post.where(company_id: @id, create_time: @time_custom, delete_flag: 0)
    @users_custom.each do |user|
      count = 0
      points = 0
      @posts.each do |post|
        if post.receiver_id.include?(user.id.to_s)
          count = count + 1
          points = points + post.points
        end
      end
      @hash[user.id] = count
      @points[user.id] = points
    end
    @hash_custom = Hash[ @hash.sort_by{ |_, v| -v } ]
    @points_custom = Hash[ @points.sort_by{ |_, v| -v } ]
  end

  def giver
    @hash = {}
    @points = {}
    @post_giving = Post.where(company_id: @id, create_time: @time_custom, delete_flag: 0).group('user_id').count
    @point_giving = Post.where(company_id: @id, create_time: @time_custom, delete_flag: 0).group('user_id').sum(:points)
    @users_custom.each do |user|
      if @post_giving[user.id].blank?
        @hash[user.id] = 0
        @points[user.id] = 0
      else
        @hash[user.id] = @post_giving[user.id]
        @points[user.id] = @point_giving[user.id]
      end
    end 
    @hash_custom = Hash[ @hash.sort_by{ |_, v| -v } ]
    @points_custom = Hash[ @points.sort_by{ |_, v| -v } ]
  end

  def hashtag
    @hashtags = @company.hashtags.split(",")
    @array = {}
    @hashtags.each do |hashtag|
      @rankings = Hashtag.where(company_id: @id, hashtag: "##{hashtag}", create_time: @time_custom, delete_flag: 0 ).group(:receiver_id).count
      @hash = {}
      @users.each do |user|
        if @rankings[user.id].blank?
          @hash[user.name] = 0
        else
          @hash[user.name] = @rankings[user.id]
        end
      end
      @array[hashtag] = Hash[ @hash.sort_by{ |_, v| v } ]
    end
  end

  def hashtagpoints
    @hashtags = @company.hashtags.split(",")
    @array = {}
    @hashtags.each do |hashtag|
      @rankings = Hashtag.where(company_id: @id, hashtag: "##{hashtag}", create_time: @time_custom, delete_flag: 0 )
      array = []
      @rankings.each do |ranking|
        array << ranking.post_id
      end
      @points = Post.where(id: array).group(:receiver_id).sum(:points)

      @hash = {}
      @users.each do |user|
        if @points[user.id].blank?
          @hash[user.name] = 0
        else
          @hash[user.name] = @points[user.id]
        end
      end
      @array[hashtag] = Hash[ @hash.sort_by{ |_, v| v } ]
    end
  end

  def allhashtag
    @num1 = 1
    @num2 = 1
    @hashtags = Hashtag.where(company_id: @id, create_time: @time_custom, delete_flag: 0).group(:hashtag).order("count_id desc").limit(10).count(:id)
    if @hashtags.empty?
      @hashtags = {}
      @lists = Hashtag.where(company_id: @id, delete_flag: 0).group(:hashtag).order("count_id desc").limit(10).count(:id)
      @lists.each do |key, value|
        @hashtags[key] = 0
      end
    end
    @hash = {}
    @hashtags.each do |hashtag|
      @ranking = Hashtag.where(company_id: @id, hashtag: hashtag[0], create_time: @time_custom, delete_flag: 0).group(:receiver_id).count
      @hash[hashtag[0]] = Hash[ @ranking.sort_by{ |_, v| -v } ]
    end
  end

  def allhashtagpoints
    @num1 = 1
    @num2 = 1
    @hashtags = Hashtag.where(company_id: @id, create_time: @time_custom, delete_flag: 0).group(:hashtag).order("count_id desc").limit(10).count(:id)
    @hashtag_points = {}
    @hashtags.each do |key, value|
      array = []
      a = Hashtag.where(hashtag: key,company_id: @id, create_time: @time_custom, delete_flag: 0)
      a.each do |a|
        array << a.post_id
      end
      @hashtag_points[key] = Post.where(id: array, company_id: @id, create_time: @time_custom, delete_flag: 0).sum(:points)
    end

    if @hashtags.empty?
      @hashtags = {}
      @lists = Hashtag.where(company_id: @id, delete_flag: 0).group(:hashtag).order("count_id desc").limit(10).count(:id)
      @lists.each do |key, value|
        @hashtags[key] = 0
      end
    end

    @hash_points = {}
    @hashtags.each do |hashtag|
      arr = []
      b = Hashtag.where(company_id: @id, hashtag: hashtag[0], create_time: @time_custom, delete_flag: 0)
      b.each do |b|
        arr << b.post_id
      end
      @ranking = Post.where(id: arr, company_id: @id, create_time: @time_custom, delete_flag: 0).group(:receiver_id).sum(:points)
      @hash_points[hashtag[0]] = Hash[ @ranking.sort_by{ |_, v| -v } ]
    end
  end

  def analytics_init
    if session[:email].present? || cookies[:email].present?
      email = session[:email] || cookies[:email]
      user = User.find_by_email(email)
      @company_id = user.company_id
      @confirm_user = User.find(params[:id])
      if @confirm_user.company_id == @company_id
      else
        redirect_to :action => "user"
      end
    end
  end

  def user
    @userid = params[:id]
    @user = User.find(@userid)
    if @user.company_id.to_i == @id.to_i
      if @user.firstname.blank?
        @user_name = @user.name
      else
        @user_name = @user.lastname + @user.firstname
      end
      if @user.gender == 0
        @user_gender = "男性"
      elsif @user.gender == 1
        @user_gender = "女性"
      else
        @user_gender = "未定"
      end
      @post_toget = Post.where(receiver_id: @userid, delete_flag: 0)
      @post_togive = Post.where(user_id: @userid, delete_flag: 0)
      # useage
      @hash = {}
      @time_custom.each do |time|
        @a = time..time.tomorrow
        @posts = Post.where(receiver_id: @userid, create_time: @a, delete_flag: 0).count
        @hash[time] = @posts
      end

      #company_hashtag
      @hashtags = @company.hashtags.split(",")
      @company_hash = {}
      @hashtags.each do |hashtag|
        @company_hashtag = Hashtag.where(receiver_id: @userid, hashtag: "##{hashtag}", create_time: @time_custom, delete_flag: 0).count
        @company_hash[hashtag] = @company_hashtag
      end
      @company_hash_custom = Hash[ @company_hash.sort_by{ |_, v| v } ]

      #all_hashtags
      @all_hashtags = Hashtag.where(receiver_id: @userid, create_time: @time_custom, delete_flag: 0).group(:hashtag).count
      @all_hashtags_custom = Hash[ @all_hashtags.sort_by{ |_, v| -v } ]
    else
      redirect_to :action => "overall"
    end  
  end

  def userpoints
    @userid = params[:id]
    @user = User.find(@userid)
    if @user.company_id.to_i == @id.to_i
      if @user.firstname.blank?
        @user_name = @user.name
      else
        @user_name = @user.lastname + @user.firstname
      end
      if @user.gender == 0
        @user_gender = "男性"
      elsif @user.gender == 1
        @user_gender = "女性"
      else
        @user_gender = "未定"
      end
      @post_toget = Post.where(receiver_id: @userid, delete_flag: 0)
      @post_togive = Post.where(user_id: @userid, delete_flag: 0)
      # useage
      @hash = {}
      @time_custom.each do |time|
        @a = time..time.tomorrow
        @posts = Post.where(receiver_id: @userid, create_time: @a, delete_flag: 0).sum(:points)
        @hash[time] = @posts
      end

      #company_hashtag
      @hashtags = @company.hashtags.split(",")
      @company_hash = {}
      @hashtags.each do |hashtag|
        company_hashtag = Hashtag.where(receiver_id: @userid, hashtag: "##{hashtag}", create_time: @time_custom, delete_flag: 0)
        array = []
        company_hashtag.each do |com|
          array << com.post_id
        end
        @company_hashtag = Post.where(id: array, receiver_id: @userid, delete_flag: 0, create_time: @time_custom).sum(:points)
        @company_hash[hashtag] = @company_hashtag
      end
      @company_hash_custom = Hash[ @company_hash.sort_by{ |_, v| v } ]

      #all_hashtags
      all_hashtags = Hashtag.where(receiver_id: @userid, create_time: @time_custom, delete_flag: 0)
      @all_hash = {}
      all_hashtags.each do |hash|
        arr = []
        posts = Hashtag.where(hashtag: hash.hashtag, receiver_id: @userid, create_time: @time_custom, delete_flag: 0)
        posts.each do |post|
          arr << post.post_id
        end
        @all_hash[hash.hashtag] = Post.where(id: arr, receiver_id: @userid, delete_flag: 0, create_time: @time_custom).sum(:points)
      end
      @all_hashtags_custom = Hash[ @all_hash.sort_by{ |_, v| -v } ]
    else
      redirect_to :action => "overall"
    end  
  end

  def usergiven
    @userid = params[:id]
    @user = User.find(@id)
    posts = Post.where(:user_id => @userid, :delete_flag => 0).order("update_time desc")
    limit = 10
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
  full_user_name: "#{post.user.lastname} #{post.user.firstname}",
  receiver_name:  post.receiver.name,
  full_receiver_name: "#{post.receiver.lastname} #{post.receiver.firstname}",
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

    top_givers = Post.where(user_id: @userid, delete_flag: 0).group(:receiver_id).order("count_all desc").limit(5).count

    @top_givers = []
    top_givers.each do | k, v |
      user = User.find(k)
      data = { name: user.name, img_src: user.img_src, count: v }
      @top_givers << data
    end

    @top_hashtags = Hashtag.where(user_id: @userid, delete_flag: 0).group(:hashtag).order("count_id desc").limit(7).count("id")
  end

  def userreceived
    @userid = params[:id]
    @user = User.find(@id)
    posts = Post.where(:receiver_id => @userid, :delete_flag => 0).order("update_time desc")

    limit = 10
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
  full_user_name: "#{post.user.lastname} #{post.user.firstname}",
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

    top_givers = Post.where(receiver_id: @userid, delete_flag: 0).group(:user_id).order("count_all desc").limit(5).count

    @top_givers = []
    top_givers.each do | k, v |
      user = User.find(k)
      data = { name: "#{user.lastname} #{user.firstname}", img_src: user.img_src, count: v }
      @top_givers << data
    end

    @top_hashtags = Hashtag.where(receiver_id: @userid, delete_flag: 0).group(:hashtag).order("count_id desc").limit(7).count("id")
  end

  def time_definition
    @company = Company.find(@id)
    if params[:start_time].blank?
      @start_time = Date.today.prev_month
    else
      @start_time = params[:start_time]
      @start_time_valid = @start_time.split("/")
      unless Date.valid_date?(@start_time_valid[0].to_i, @start_time_valid[1].to_i, @start_time_valid[2].to_i)
        @start_time = Date.today.prev_month
      end
    end
    if params[:end_time].blank?
      @end_time = Date.today
    else
      @end_time = params[:end_time]
      @end_time_valid = @end_time.split("/")
      unless Date.valid_date?(@end_time_valid[0].to_i, @end_time_valid[1].to_i, @end_time_valid[2].to_i)
        @end_time = Date.today
      end
    end
    @time_custom = @start_time.to_date..@end_time.to_date
  end 

  def basic_info
    @company = Company.find(@id)
    @users = User.where(company_id: @id, delete_flag: 0)
    @users_custom = User.where(company_id: @id, delete_flag: 0)
    @team_lists = []
    @teams = Team.where(company_id: @id, delete_flag: 0)
    @teams.each do |team|
      hash = {}
      each_team = []
      each_team << team.manager_id
      team.member_ids.split(",").each do |mem|
        unless mem.to_i == 0
        each_team << mem.to_i
        end
      end
      hash[:id] = team.id
      hash[:team_name] = team.team_name
      hash[:members] = each_team
      @team_lists << hash
    end
    # 所属無しメンバー
    # 全社員のid取得
    user_ids = []
    User.where(company_id: @id, delete_flag: 0).each do |user|
      user_ids << user.id
    end
    # 何かしらのチームに属してるid取得
    in_team_user_ids = []
    @teams.each do |team|
      in_team_user_ids.push(team.member_ids.split(",").delete("0"))
      in_team_user_ids.push(team.manager_id)
      in_team_user_ids.flatten!
      in_team_user_ids.uniq
    end
    # 何もチームに属していないid取得
    in_team_user_ids.each do |id|
      user_ids.delete(id.to_i)
    end
    # 何もチームに属していないユーザーの配列
    @non_team_user_ids = []
    user_ids.each do |id|
      unless id == 0
      @non_team_user_ids << id
      end
    end
    # ハッシュ作成
    non_team = {
      :id => 0,
      :team_name => "所属なし",
      :members => @non_team_user_ids
    }
    @team_lists << non_team
  end

  def ip_address_limit
    @company = Company.find(@id)
    ip = request.remote_ip
    allowed_ips = @company.allowed_ips.split(",") if @company.allowed_ips.present?
    if @company.ip_limit_flag == 1
      unless allowed_ips.include?(ip.to_s)
        redirect_to "/"
      end
    end
  end
end
