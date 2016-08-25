class AnalyticsController < ApplicationController

  before_filter :init, :authenticate_company
  before_filter :init_url
  before_action :time_definition, only:[:index, :giver, :hashtag, :allhashtag]
  before_action :basic_info, only:[:overall, :index, :giver, :hashtag, :allhashtag]

  def init
    if session[:company_id].present? || cookies[:company_id].present?
      @id = session[:company_id] || cookies[:company_id]
    end
  end

  def overall
    # before_ajax
    @start_register = @company.create_time.to_date
    @time_now = Date.today
    @time_range = @start_register..@time_now
    @hash = {}
    @time_range.each do |time|
      @a = time..time.tomorrow
      @post = Post.where(company_id: @id, create_time: @a).count
      @hash[time] = @post
    end

    # after_ajax
    if params[:start_time].blank?
      @start_time_ajax = @company.create_time.to_date
    else  
      @start_time_ajax = params[:start_time].to_date
    end

    if params[:end_time].blank?
      @end_time_ajax = Date.today
    else
      @end_time_ajax = params[:end_time].to_date
    end
    @time_custom = @start_time_ajax..@end_time_ajax

    @ajaxhash = {}
    @time_custom.each do |time|
      @a_ajax = time..time.tomorrow
      @post_ajax = Post.where(company_id: @id, create_time: @a_ajax).count
      @ajaxhash[time] = @post_ajax
    end
    logger.debug "-----------"
    logger.debug @ajaxhash
  end

  def index
    # before_ajax
    @hash = {}
    @post_recieved = Post.all.group('receiver_id').count
    @users.each do |user|
      if @post_recieved[user.id].blank?
        @hash[user.name] = 0
      else
        @hash[user.name] = @post_recieved[user.id]
      end
    end 
    @hash_custom = Hash[ @hash.sort_by{ |_, v| -v } ]
    
    # after_ajax
    @hash_ajax = {}
    @post_recieved = Post.where(:create_time => @time_custom).group('receiver_id').count
    @users.each do |user|
      if @post_recieved[user.id].blank?
        @hash_ajax[user.name] = 0
      else
        @hash_ajax[user.name] = @post_recieved[user.id]
      end
    end 
    @hash_ajax_custom = Hash[ @hash_ajax.sort_by{ |_, v| -v } ]
  end

  def giver
    # before_ajax
    @hash = {}
    @post_giving = Post.all.group('user_id').count
    @users.each do |user|
      if @post_giving[user.id].blank?
        @hash[user.name] = 0
      else
        @hash[user.name] = @post_giving[user.id]
      end
    end 
    @hash_custom = Hash[ @hash.sort_by{ |_, v| -v } ]
    
    # after_ajax
    @hash_ajax = {}
    @post_giving = Post.where(:create_time => @time_custom).group('user_id').count
    @users.each do |user|
      if @post_giving[user.id].blank?
        @hash_ajax[user.name] = 0
      else
        @hash_ajax[user.name] = @post_giving[user.id]
      end
    end 
    @hash_ajax_custom = Hash[ @hash_ajax.sort_by{ |_, v| -v } ]
  end

  def hashtag
    # before_ajax
    @hashtags = @company.hashtags.split(",")
    @array = {}
    @hashtags.each do |hashtag|
      @rankings = Hashtag.where(company_id: @id, hashtag: "##{hashtag}" ).group(:receiver_id).count
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
    # after_ajax
    @array_ajax = {}
    @hashtags.each do |hashtag|
      @rankings_ajax = Hashtag.where(company_id: @id, hashtag: "##{hashtag}", create_time: @time_custom ).group(:receiver_id).count
      @hash_ajax = {}
      @users.each do |user|
        if @rankings_ajax[user.id].blank?
          @hash_ajax[user.name] = 0
        else
          @hash_ajax[user.name] = @rankings_ajax[user.id]
        end
      end
      @array_ajax[hashtag] = Hash[ @hash_ajax.sort_by{ |_, v| v } ]
    end
  end

  def allhashtag
    @hashtags = Hashtag.where(company_id: @id).group(:hashtag).order("count_id asc").count(:id)

    @hashtag_lists = Hashtag.where(company_id: @id).group(:hashtag)
    @hash = {}
    @hashtag_lists.each do |hashtag|
      @ranking = Hashtag.where(company_id: @id, hashtag: hashtag.hashtag).group(:receiver_id).count
      @ranking_hash = {}
      @users.each do |user|
        if @ranking[user.id].blank?
          @ranking_hash[user.name] = 0
        else
          @ranking_hash[user.name] = @ranking[user.id]
        end
      end
      @hash[hashtag.hashtag] = Hash[ @ranking_hash.sort_by{ |_, v| -v } ]

      @hashtags.first(10).each do |hashtag|
        logger.debug "----------"
        logger.debug @hash[hashtag[0]]
      end

    end
  end

  def user
    @num = 0
  end

  def basic_info
    @company = Company.find(@id)
    @users = User.where(company_id: @id)
  end

  def time_definition
    @start_time = params[:start_time]
    @end_time = params[:end_time]
    @time_custom = @start_time..@end_time
  end 

end
