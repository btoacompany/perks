class AnalyticsController < ApplicationController

  before_filter :init, :authenticate_user
  before_filter :init_url, :validate_user
  before_action :time_definition, only:[:overall, :index, :giver, :hashtag, :allhashtag, :user]
  before_action :basic_info, only:[:overall, :index, :giver, :hashtag, :allhashtag, :user]

  def init
    if session[:email].present? || cookies[:email].present?
      email = session[:email] || cookies[:email]
      user = User.find_by_email(email)
      if user.admin == 1
	@id = user.company_id
	@user_id = user.id
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
    @time_custom.each do |time|
      @a = time..time.tomorrow
      @post = Post.where(company_id: @id, create_time: @a, delete_flag: 0).count
      @hash[time] = @post
    end
  end

  def index
    @hash = {}
    @post_recieved = Post.where(company_id: @id, create_time: @time_custom, delete_flag: 0).group('receiver_id').count
    @users_custom.each do |user|
      if @post_recieved[user.id].blank?
        @hash[user.id] = 0
      else
        @hash[user.id] = @post_recieved[user.id]
      end
    end 
    @hash_custom = Hash[ @hash.sort_by{ |_, v| -v } ]
  end

  def giver
    @hash = {}
    @post_giving = Post.where(company_id: @id, create_time: @time_custom, delete_flag: 0).group('user_id').count
    @users_custom.each do |user|
      if @post_giving[user.id].blank?
        @hash[user.id] = 0
      else
        @hash[user.id] = @post_giving[user.id]
      end
    end 
    @hash_custom = Hash[ @hash.sort_by{ |_, v| -v } ]
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

  def usergiven
    @userid = params[:id]
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

    top_givers = Post.where(user_id: @userid, delete_flag: 0).group(:receiver_id).order("count_all desc").limit(5).count

    @top_givers = []
    top_givers.each do | k, v |
      user = User.find(k)
      data = { name: user.name, img_src: user.img_src, count: v }
      @top_givers << data
    end

    @top_hashtags = Hashtag.where(user_id: @userid, delete_flag: 0).group(:hashtag).order("count_id desc").limit(7).count("id")
  end

  def time_definition
    @company = Company.find(@id)
    if params[:start_time].blank?
      @start_time = @company.create_time
    else
      @start_time = params[:start_time]
    end
    if params[:end_time].blank?
      @end_time = Date.today
    else
      @end_time = params[:end_time]
    end
    @time_custom = @start_time.to_date..@end_time.to_date
  end 

  def basic_info
    @company = Company.find(@id)
    @users = User.where(company_id: @id, delete_flag: 0)
    @users_custom = User.where(company_id: @id, delete_flag: 0)
  end


end
