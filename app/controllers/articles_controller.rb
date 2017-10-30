class ArticlesController < ApplicationController
  impressionist actions: [:index, :show]
  before_filter :init_url
  before_action :init

  def init
    if session[:email].present? || cookies[:email].present?
      email = session[:email] || cookies[:email]
      user = User.find_by_email(email)
      unless user.nil?
        if user.admin == 1
          @id = user.company_id
          @user_id = user.id
        end
      else
        redirect_to "/logout"
      end
      @company = Company.find(@id)
    else
      logout
    end
  end

  def index
    @articles = Article.where(company_id: @company.id, is_deleted: 0, is_casual: 0).order(updated_at: :desc)
  end

  def new
  	@articles = Article.new
  	@categories = Category.where(company_id: @company.id, is_deleted:0, company_id: @company.id)
  end

  def create
    ActiveRecord::Base.transaction do
      @article = Article.create(
				company_id: @company.id,
				category_id: params[:category_id],
				title: params[:title],
				description: params[:description],
        is_casual: params[:is_casual]
      	)

      if params[:tags].present?
        params[:tags].uniq.each do |email|
          user = User.find_by(email: email)
          if user
            Tag.create(
              article_id: @article.id,
              user_id: user.id
              )
          end
        end
      end

      if params[:texts].present?
        params[:texts].each do |key, value|
          @text = Text.create(
            article_id:   @article.id,
            content:      value,
            place_number: key.to_i,
          )
        end
      end

      if params[:links].present?
        params[:links].each do |key, value|
          @link = Link.create(
            article_id:   @article.id,
            content:     value[0],
            url:          value[1],
            place_number: key.to_i,
          )
        end
      end

      if params[:quotations].present?
        params[:quotations].each do |key, value|
          @quotation = Quotation.create(
            article_id:    @article.id,
            quotation:     value[0],
            quotation_url: value[1],
            place_number:  key.to_i,
          )
        end
      end

      if params[:paragraph_titles].present?
        params[:paragraph_titles].each do |key, value|
          @title = Title.create(
            article_id:   @article.id,
            content:      value,
            place_number: key.to_i,
          )
        end
      end

      if params[:images].present?
	      params[:images].each do |key, value|
	      	src	  = value
	      	src_ext	  = File.extname(src.original_filename)
	      	s3  = Aws::S3::Resource.new
	      	obj = s3 .bucket(@s3_bucket).object("article/article_#{@article.id}_pic#{src_ext}")
	      	obj.upload_file src.tempfile, {acl: 'public-read'}
	      	@image = Image.create(
	      		article_id:   @article.id,
	      	  img_src:      obj.public_url, 
	          place_number: key.to_i
	      	)
	      end
	    end
    end
    redirect_to company_articles_path, notice: "記事を作成しました。"
    # rescue => e
    # redirect_to "company_article_new_path", notice: "失敗しました。"
  end

  def show
    @user = User.find(@id)
    @users    = User.where(:company_id => @company.id, :delete_flag => 0)
    @departments = Department.where(company_id: @company.id, delete_flag: 0)
    @total_receive_message = Post.where(company_id: @company.id, delete_flag: 0, receiver_id: @user.id).count
    @user_ids, @user_fullnames  = User.autocomplete_suggestions(@company.id)
    @article = Article.find_by(id: params[:id], is_deleted: 0, company_id: @company.id)
    @user_posted_contents = Article.where(company_id: @company.id, is_casual: 1)
	    if @article
      @banner = Banner.find_by(company_id: @company.id, is_deleted: 0)
      impressionist(@article, nil, :unique => [:session_hash])
	    @tags = @article.tags
	    # @first_pic = Image.find_by(article_id: @article.id)
	    @contents = []
	    @titles = @article.titles
	    unless @titles.blank?
	      @titles.each do |item|
	        @data = {
	          :data_type => "title",
	          :place_number => item.place_number.to_i,
	          :title => item.content
	        }
	        @contents << @data
	      end
	    end

	    @texts = @article.texts
	    unless @titles.blank?
	      @texts.each do |item|
	        @data = {
	          :data_type => "text",
	          :place_number => item.place_number.to_i,
	          :text => item.content
	        }
	        @contents << @data
	      end
	    end

	    @links = @article.links
	    unless @links.blank?
	      @links.each do |item|
	        @data = {
	          :data_type => "link",
	          :place_number => item.place_number.to_i,
	          :link_title => item.content,
	          :link_url => item.url
	        }
	        @contents << @data
	      end
	    end

	    @quotations = @article.quotations
	    unless @quotations.blank?
	      @quotations.each do |item|
	        @data = {
	          :data_type => "quotation",
	          :place_number => item.place_number.to_i,
	          :quotation_title => item.content,
	          :quotation_url => item.url
	        }
	        @contents << @data
	      end
	    end

	    @images = @article.images
	    unless @images.blank?
	      @images.each do |item|
	        @data = {
	          data_type:   "image",
	          place_number: item.place_number.to_i,
	          img_src:      item.img_src,
	        }
	        @contents << @data
	      end
	    end
	    @all_contents = @contents.sort{|aa, bb| aa[:place_number] <=> bb[:place_number]}

	    @title = "#{@article.title} | BetterEngage (ベター・エンゲージ)"
	    @description = @article.description
	    # @base_url = "https://betterengagee.com/blog/article/#{@article.id}"
	    # @image_url = @first_pic.authenticated_image_url(:medium)
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


      posts = Post.where(:receiver_id => @id, :delete_flag => 0).order("update_time desc")
      process_posts = process_paging(posts)

      @posts = []
      data = {}

      process_posts.each do | post |
        data = process_post(post)
        @posts << data
      end

      unless $showoff_ranking.include?(@user.company_id)
        top_receiver = Post.where(receiver_id: @id, delete_flag: 0).group(:user_id).order("count_all desc").limit(5).count
        process_top_receivers(top_receiver)
        @top_hashtags = Hashtag.where(company_id: @company_id, receiver_id: @id, delete_flag: 0).group(:hashtag).order("count_id desc").limit(7).count("id")
      else 
        @last_month = Date.today.prev_month.beginning_of_month..Date.today.beginning_of_month
        top_givers = Post.where(company_id: @company_id, delete_flag: 0, create_time: @last_month ).group(:user_id).order("count_all desc").limit(3).count
        process_top_givers(top_givers)

        top_receivers = Post.where(company_id: @company_id, delete_flag: 0, create_time: @last_month).group(:receiver_id).order("count_all desc").limit(3).count
        process_top_receivers(top_receivers)
      end
	  else
	  	redirect_to :root
    end
  end

  def edit
    @num = 1
    @categories = Category.where(company_id: @company.id, is_deleted:0, company_id: @company.id)
    @article = Article.find(params[:id])
    @tags = User.where(is_deleted: 0, article_id: @article.id)
    # @article_tags = ArticleTag.where(article_id: @article.id).pluck(:tag_id)
    @contents = []
    @titles = @article.titles
    unless @titles.blank?
      @titles.each do |item|
        @data = {
          :data_type => "title",
          :place_number => item.place_number.to_i,
          :title => item.title
        }
        @contents << @data
      end
    end

    @texts = @article.texts
    unless @titles.blank?
      @texts.each do |item|
        @data = {
          :data_type => "text",
          :place_number => item.place_number.to_i,
          :text => item.text
        }
        @contents << @data
      end
    end

    @links = @article.links
    unless @links.blank?
      @links.each do |item|
        @data = {
          :data_type => "link",
          :place_number => item.place_number.to_i,
          :link_title => item.link_title,
          :link_url => item.url
        }
        @contents << @data
      end
    end

    @quotations = @article.quotations
    unless @quotations.blank?
      @quotations.each do |item|
        @data = {
          :data_type => "quotation",
          :place_number => item.place_number.to_i,
          :quotation_title => item.quotation,
          :quotation_url => item.url
        }
        @contents << @data
      end
    end

    @images = @article.images
    unless @images.blank?
      @images.each do |item|
        @data = {
          :data_type => "image",
          :place_number => item.place_number.to_i,
          :image => item,
          :image_title => item.image_title,
          :image_url => item.image_url ,
          :id => item.id
        }
        @contents << @data
      end
    end

    @all_contents = @contents.sort{|aa, bb|
      aa[:place_number] <=> bb[:place_number]
    }
  end

  def update
    ActiveRecord::Base.transaction do
      @article = Article.find(params[:id])

      @article.category_id = params[:category_id]
      @article.title       = params[:title]
      @article.description = params[:description]
      @article.is_casual   = params[:is_casual]
      @article.save

      # ArticleTag.where(article_id: @article.id).destroy_all
      Title.where(article_id: @article.id).destroy_all
      Text.where(article_id: @article.id).destroy_all
      Link.where(article_id: @article.id).destroy_all
      Quotation.where(article_id: @article.id).destroy_all

      if params[:paragraph_titles].present?
        params[:paragraph_titles].each do |key, value|
          @title = Title.create(
            article_id:   @article.id,
            content:      value,
            place_number: key.to_i,
          )
        end
      end

      if params[:texts].present?
        params[:texts].each do |key, value|
          @text = Text.create(
            article_id:   @article.id,
            content:      value,
            place_number: key.to_i,
          )
        end
      end

      if params[:links].present?
        params[:links].each do |key, value|
          @link = Link.create(
            article_id:   @article.id,
            content:     value[0],
            url:          value[1],
            place_number: key.to_i,
          )
        end
      end

      if params[:quotations].present?
        params[:quotations].each do |key, value|
          @quotation = Quotation.create(
            article_id:    @article.id,
            quotation:     value[0],
            quotation_url: value[1],
            place_number:  key.to_i,
          )
        end
      end

      if params[:images].present?
        params[:images].each do |key, value|
          src    = value
          src_ext    = File.extname(src.original_filename)
          s3  = Aws::S3::Resource.new
          obj = s3 .bucket(@s3_bucket).object("article/article_#{@article.id}_pic#{src_ext}")
          obj.upload_file src.tempfile, {acl: 'public-read'}
          @image = Image.create(
            article_id:   @article.id,
            img_src:      obj.public_url, 
            place_number: key.to_i
          )
        end
      end
    end
    redirect_to company_articles_path, notice: "記事を作成しました。"
    rescue => e
    redirect_to company_articles_path, notice: "失敗しました。"
  end

  def destory
  	@article = Article.find(params[:id])
  	if @article
  		@article.is_deleted = 1
  		@article.save
  	end
  	redirect_to company_articles_path
  end

  def publish
  	@article = Article.find(params[:id])
  	if @article
  		if @article.is_published == 0
  		  @article.is_published = 1
  		elsif @article.is_published == 1
  			@article.is_published = 0
  	  end
  		@article.save
  	end
  	redirect_to company_articles_path
  end

  def casual
    @articles = Article.where(company_id: @company.id, is_deleted: 0, is_casual: 1).order(updated_at: :desc)
  end

  def update_is_new
    @article = Article.find(params[:id])
    if @article
      if @article.is_new == 0
        @article.is_new = 1
      elsif @article.is_new == 1
        @article.is_new = 0
      end
      @article.save
    end
    redirect_to company_articles_path
  end

  def like
    like = ArticleLike.find_by(user_id: user_id, article_id: params[:post_id])
    if like.present?
    	if like.is_liked == 0
    		like.is_liked = 1
    	elsif like.is_liked == 1
        like.is_liked = 0
      end
      like.save
      redirect_to protocol: @protocol, :controller => "articles", :action => "show", id: like.article_id
    else
    	@like = ArticleLike.create(
      	article_id: params[:post_id].to_i,
    		user_id: user_id,
    		is_liked: 1
    		)
      redirect_to protocol: @protocol, :controller => "articles", :action => "show", id: @like.article_id
    end
    # redirect_to "/company/article/params[:article_id]"
  end

  def receiver_ranking(user)
    last_week =  Date.today.prev_week.beginning_of_week..Date.today.prev_week.end_of_week
    this_week = Date.today.beginning_of_week..Date.today.end_of_week
    
    @receiver_ratio = []
    @this_week_posts = Post.where(company_id: @company_id, delete_flag: 0, receiver_id: user.id, create_time: this_week).count
    @receiver_ratio << @this_week_posts

    if this_week.cover?(user.create_time)
      @receiver_ratio << "-"
    else
      @last_week_posts = Post.where(company_id: @company_id, delete_flag: 0, receiver_id: user.id, create_time: last_week).count
      @last_week_posts = 1 if @last_week_posts == 0
      @receiver_ratio << (@this_week_posts.to_f - @last_week_posts.to_f) / @last_week_posts.to_f * 100
      return @receiver_ratio
    end
  end

  def giver_ranking(user)
    last_week =  Date.today.prev_week.beginning_of_week..Date.today.prev_week.end_of_week
    this_week = Date.today.beginning_of_week..Date.today.end_of_week

    @giver_ratio =[]
    @this_week_posts = Post.where(company_id: @company_id, delete_flag: 0, user_id: user.id, create_time: this_week).count
    @giver_ratio << @this_week_posts

    if this_week.cover?(user.create_time)
      @giver_ratio << "-"
    else
      @last_week_posts = Post.where(company_id: @company_id, delete_flag: 0, user_id: user.id, create_time: last_week).count
      @last_week_posts = 1 if @last_week_posts == 0
      @giver_ratio << (@this_week_posts.to_f - @last_week_posts.to_f) / @last_week_posts.to_f * 100
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

  def send_release_mail
    @users = User.where(company_id: @company.id, delete_flag: 0)
    @users.each do |user|
      data = {
        email:      user.email,
        subject: params[:subject],
        description: params[:description]        
      }
      CompanyMailer.release_article(data).deliver_now
    end
  end
end
