class ArticlesController < ApplicationController
  impressionist actions: [:index, :show]
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
    if Rails.env.production?
      @s3_url = "https://s3-ap-northeast-1.amazonaws.com/prizy"
      @s3_bucket = "prizy"
    elsif Rails.env.development?
      @s3_url = "https://s3-ap-northeast-1.amazonaws.com/btoa-img"
      @s3_bucket = "btoa-img"
    end
  end

  def index
    @articles = Article.where(company_id: @company.id, is_deleted: 0)
  end

  def new
  	@articles = Article.new
  	@categories = Category.where(company_id: @company.id, is_deleted:0, company_id: @company.id)
  	@tags = Tag.where(company_id: @company.id)
  end

  def create
    ActiveRecord::Base.transaction do
      @article = Article.create(
				company_id: @company.id,
				category_id: nil,
				title: params[:title],
				description: params[:description],
      	)

      # if params[:tags].present?
      #   params[:tags].each do |tag_id|
      #     @articletag = {
      #     	article_id: @article.id,
      #     	tag_id: tag_id.to_i
      #     }
      #     params[:article_id] = @article.id
      #     params[:tag_id] = tag_id.to_i
      #     @articletag.save_record(params)
      #   end
      # end

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
	      	obj = s3.bucket(@s3_bucket).object("article/article_#{@article.id}_pic#{src_ext}")
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
    @article = Article.find_by(id: params[:id], is_deleted: 0, company_id: @company.id)
	    if @article
      impressionist(@article, nil, :unique => [:session_hash])
	    @tags = @article.tags.where(is_deleted: 0)
	    @article_tags = ArticleTag.where(article_id: @article.id).pluck(:tag_id)
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
	  else
	  	redirect_to :root
    end
  end

  def edit
  end

  def update
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

  def like
    like = ArticleLike.find_by(user_id: @user_id, article_id: params[:article_id])
    if like.present?
    	if like.is_liked == 0
    		like.is_liked = 1
    	elsif like.is_liked == 1
        like.is_liked = 0
      end
      like.save
    else
    	 @like = ArticleLike.create(
    		article_id: params[:article_id],
    		user_id: @user_id,
    		is_liked: 1
    		)
    end
    redirect_to "/company/article/params[:article_id]"
  end
end
