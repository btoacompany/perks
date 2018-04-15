class ArticlesController < ApplicationController
  impressionist actions: [:index, :show]
  before_filter :init_url, :authenticate_user
  before_action :init

  class << self
    def send_each(user)
      teams = Team.of_company(user.company_id).available
      # 所属
      belonging = nil
      teams.map { |team| belonging = team if team.member_ids.present? && team.member_ids.split(",").include?(user.id.to_s) }
      if belonging
        member_ids = belonging.member_ids.split(",") - [user.id]
        if member_ids.count >= 2
          two_targets_from_team = member_ids.sample(2)
        else
          teams = Team.where(department_id: belonging.department_id).available
          department_members = Array.new
          teams.each do |team|
            if team.member_ids.present?
              team.member_ids.split(",").each do |id|
                department_members.push(id)
              end
            end
          end
          two_targets_from_team = department_members.sample(2)
        end
      end

      articles = Article.of_company(user.company_id).available.pluck(:id)
      target_from_article = Tag.where(article_id: articles).where.not(user_id: user.id).where.not(user_id: two_targets_from_team).pluck(:user_id).sample(1)
        
      # targets = {team: user, ...}
      targets = Hash.new
      if belonging
        target_users = two_targets_from_team + target_from_article
      else
        target_users = target_from_article
      end
      target_users = User.available.of_company(user.company_id).where(id: target_users)

      target_users.each do |user|
        belonging = nil
        teams.map { |team| belonging = team if team.member_ids.present? && team.member_ids.split(",").include?(user.id.to_s) }
        targets.store(belonging, user)
      end

      data = {
        user: user,
        email: Rails.env.production? ? user.email : "naoto.udagawa1230@gmail.com",
        target: targets
      }
      # CompanyMailer.recommend_mail(data).deliver_now
    end

    def batch
      @users = User.available.of_company(32)
      @users.each do |user|
        send_each(user) 
        sleep 1
      end
    end
  end

  def init
    if session[:id].present? || cookies[:id].present?
      @id = session[:id] || cookies[:id]
      user = User.find(@id)
      @user_id = user.id
      @company = Company.find(user.company_id)
    else
      logout
    end
  end

  def index
    @user = User.find(@user_id)
    if @user.admin == 0
      redirect_to :root
    end
    @articles = Article.where(company_id: @company.id, is_deleted: 0, is_casual: 0).order(updated_at: :desc)
  end

  def new
    @user = User.find(@user_id)
    if @user.admin == 0
      redirect_to :root
    end
  	@articles = Article.new
    @user_ids, @user_fullnames  = User.autocomplete_suggestions(@company.id)
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

      if @article.valid?
        if params[:tag_user_ids].present?
          params[:tag_user_ids].uniq.each do |id|
            user = User.find(id)
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
              article_id:     @article.id,
              content:        value[0],
              url:            value[1],
              place_number:   key.to_i,
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
            is_eye_catch = 0
            if params[:is_eye_catch] == key
              is_eye_catch=1
            end

  	      	src	  = value
  	      	src_ext	  = File.extname(src.original_filename)
  	      	s3  = Aws::S3::Resource.new
            @last_image = Image.last
  	      	obj = s3 .bucket(@s3_bucket).object("article/article_#{@last_image.id + 1}_pic#{src_ext}")
  	      	obj.upload_file src.tempfile, {acl: 'public-read'}

  	      	@image = Image.create(
  	      		article_id:   @article.id,
  	      	  img_src:      obj.public_url, 
  	          place_number: key.to_i,
              is_eye_catch:  is_eye_catch
  	      	)
  	      end
  	    end

        if params[:nametag_user_ids].present?
          params[:nametag_user_ids].each do |key, nametags|
            nametags.uniq.each do | id |
              user = User.find(id)
              if user
                Tag.create(
                  article_id: @article.id,
                  user_id: user.id,
                  place_number: key.to_i,
                  )
              end
            end
          end
        end
        if @article.is_casual == 0
          redirect_to company_articles_path, notice: "記事を作成しました。"
        else
          redirect_to company_casual_articles_path, notice: "記事を作成しました。"
        end
      else
        error_message = @article.errors.full_messages[0] if @article.errors.full_messages
        redirect_to company_article_new_path, notice: "#{error_message}"
      end
    end
    rescue => e
    redirect_to company_articles_path, notice: "失敗しました。"
  end

  def show
    @user = User.find(@user_id)
    @users    = User.where(:company_id => @company.id, :delete_flag => 0)
    @departments = Department.where(company_id: @company.id, delete_flag: 0).order(sort: :asc)
    @total_receive_message = Post.where(company_id: @company.id, delete_flag: 0, receiver_id: @user.id).count
    @user_ids, @user_fullnames  = User.autocomplete_suggestions(@company.id)
    @article = Article.find_by(id: params[:id], is_deleted: 0, company_id: @company.id)
    @user_posted_contents = Article.where(company_id: @company.id, is_casual: 1, is_deleted: 0, is_published: 1)
	  
    user_posts = @user_posted_contents
    @first_images = {}
    
    user_posts.each do | post |
      set_first_image(post)
    end 

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
	    unless @texts.blank?
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

      @nametags = @article.tags
      testdata = {}

      unless @nametags.blank?
        @nametags.each do |item|
          place_number = item.place_number.to_i
          #ignore if place number is 0 (for general tags)
          if place_number > 0
            fullname = "#{item.user.lastname + item.user.firstname}"

            if testdata[place_number].present?
              testdata[place_number][:user_ids] << item.user_id
              testdata[place_number][:user_fullnames] << fullname
              testdata[place_number][:ids] << item.id
            else

              testdata[place_number] = {
                user_ids: [item.user_id],
                user_fullnames: [fullname],
                ids: [item.id]
              }
            end
          end
        end
      end

      testdata.each do |key, item|
        @data = {
              data_type: "nametag",
              place_number: key.to_i,
              user_ids: item[:user_ids] ,
              user_fullnames: item[:user_fullnames],
              tag_count: item[:user_ids].count,
              id: item[:ids]
        }

        @contents << @data
      end

	    @all_contents = @contents.sort{|aa, bb| aa[:place_number] <=> bb[:place_number]}

	    @title = "#{@article.title}"
	    @description = @article.description
	    # @base_url = "https://betterengagee.com/blog/article/#{@article.id}"
	    # @image_url = @first_pic.authenticated_image_url(:medium)
      # weekly_ranking
      receiver_ranking(@user)
      giver_ranking(@user)


      # posts = Post.where(:receiver_id => @id, :delete_flag => 0).order("update_time desc")
      # process_posts = process_paging(posts)

      # @posts = []
      # data = {}

      # process_posts.each do | post |
      #   data = process_post(post)
      #   @posts << data
      # end

      # unless $showoff_ranking.include?(@user.company_id)
      #   top_receiver = Post.where(receiver_id: @id, delete_flag: 0).group(:user_id).order("count_all desc").limit(5).count
      #   process_top_receivers(top_receiver)
      #   @top_hashtags = Hashtag.where(company_id: @company_id, receiver_id: @id, delete_flag: 0).group(:hashtag).order("count_id desc").limit(7).count("id")
      # else 
      #   @last_month = Date.today.prev_month.beginning_of_month..Date.today.beginning_of_month
      #   top_givers = Post.where(company_id: @company_id, delete_flag: 0, create_time: @last_month ).group(:user_id).order("count_all desc").limit(3).count
      #   process_top_givers(top_givers)

      #   top_receivers = Post.where(company_id: @company_id, delete_flag: 0, create_time: @last_month).group(:receiver_id).order("count_all desc").limit(3).count
      #   process_top_receivers(top_receivers)
      # end
	  else
	  	redirect_to :root
    end
  end

  def edit
    @user = User.find(@user_id)

    if @user.admin == 0
      redirect_to :root
    end

    @user_ids, @user_fullnames  = User.autocomplete_suggestions(@company.id)
    @num = 1
    @article = Article.find(params[:id])

    logger.debug(@article.tags.count)

    @article.tags.each do |tag|
      logger.debug(tag)
    end

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
    unless @texts.blank?
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
          data_type: "image",
          place_number: item.place_number.to_i,
          image_url: item.img_src ,
          id: item.id,
          is_eye_catch: item.is_eye_catch.to_i
        }
        @contents << @data
      end
    end

    @nametags = @article.tags
    testdata = {}

    unless @nametags.blank?
      @nametags.each do |item|
        place_number = item.place_number.to_i
        #ignore if place number is 0 (for general tags)
        if place_number > 0
          fullname = "#{item.user.lastname + item.user.firstname}"

          if testdata[place_number].present?
            testdata[place_number][:user_ids] << item.user_id
            testdata[place_number][:user_fullnames] << fullname
            testdata[place_number][:ids] << item.id
          else

            testdata[place_number] = {
              user_ids: [item.user_id],
              user_fullnames: [fullname],
              ids: [item.id]
            }
          end
        end
      end
    end

    testdata.each do |key, item|
      @data = {
            data_type: "nametag",
            place_number: key.to_i,
            user_ids: item[:user_ids] ,
            user_fullnames: item[:user_fullnames],
            tag_count: item[:user_ids].count,
            id: item[:ids]
      }

      @contents << @data
    end

    @all_contents = @contents.sort{|aa, bb|
      aa[:place_number] <=> bb[:place_number]
    }
  end

  def update
    ActiveRecord::Base.transaction do
      @article = Article.find(params[:id])

      @article.title       = params[:title]
      @article.description = params[:description]
      @article.is_casual   = params[:is_casual]
      @article.save

      if @article.valid?
        Title.where(article_id: @article.id).destroy_all
        Text.where(article_id: @article.id).destroy_all
        Link.where(article_id: @article.id).destroy_all
        Quotation.where(article_id: @article.id).destroy_all
        Tag.where(article_id: @article.id).destroy_all

        if params[:paragraph_titles].present?
          params[:paragraph_titles].each do |key, value|
            @title = Title.create(
              article_id:   @article.id,
              content:      value,
              place_number: key.to_i,
            )
          end
        end

        if params[:tag_user_ids].present?
          params[:tag_user_ids].uniq.each do |id|
            user = User.find(id)
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
              content:     value[0],
              url: value[1],
              place_number:  key.to_i,
            )
          end
        end

        if params[:images].present?
          params[:images].each do |key, value|
            is_eye_catch = 0
            if params[:is_eye_catch].to_i == key.to_i
              is_eye_catch=1
            end

            if value.present? && value.class == Array
              image = Image.find_by(img_src: value[0])
              image.update_attribute(:place_number, key.to_i) if image
              image.update_attribute(:is_eye_catch, is_eye_catch.to_i) if image
            else
              src    = value
              src_ext    = File.extname(src.original_filename)
              s3  = Aws::S3::Resource.new
              @last_image = Image.last
              obj = s3 .bucket(@s3_bucket).object("article/article_#{@last_image.id + 1}_pic#{src_ext}")
              obj.upload_file src.tempfile, {acl: 'public-read'}
              @image = Image.create(
                article_id:   @article.id,
                img_src:      obj.public_url, 
                place_number: key.to_i,
                is_eye_catch: is_eye_catch.to_i
              )

            end
          end
        end

        if params[:nametag_user_ids].present?
          params[:nametag_user_ids].each do |key, nametags|
            nametags.uniq.each do | id |
              user = User.find(id)
              if user
                Tag.create(
                  article_id: @article.id,
                  user_id: user.id,
                  place_number: key.to_i,
                  )
              end
            end
          end
        end
        redirect_to company_articles_path, notice: "記事を更新しました。"
      else
        error_message = @article.errors.full_messages[0] if @article.errors.full_messages
        redirect_to "/company/article/#{@article.id}/edit", notice: "#{error_message}"
      end
    end

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

  def image
    @image = Image.find(params[:id])
  end

  def image_update
    @image = Image.find(params[:id])
    if @image && params[:img_src].present?
      src    = params[:img_src]
      src_ext    = File.extname(src.original_filename)
      s3  = Aws::S3::Resource.new
      obj = s3 .bucket(@s3_bucket).object("article/article_#{@image.id}_pic#{src_ext}")
      obj.upload_file src.tempfile, {acl: 'public-read'}
      @image.img_src = obj.public_url
      @image.save
    end
    redirect_to "/company/article/#{@image.article_id}/edit"
  end

  def image_delete
    @image = Image.find(params[:id])
    @image.destroy
    redirect_to "/company/article/#{@image.article_id}/edit"
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
    last_week =  Date.today.prev_week.beginning_of_week...Date.today.beginning_of_week
    this_week = Date.today.beginning_of_week...Date.today.next_week.beginning_of_week
    
    @receiver_ratio = []
    @this_week_posts = Post.where(company_id: @company.id, delete_flag: 0, receiver_id: user.id, create_time: this_week).count
    @receiver_ratio << @this_week_posts

    if this_week.cover?(user.create_time)
      @receiver_ratio << "-"
    else
      @last_week_posts = Post.where(company_id: @company.id, delete_flag: 0, receiver_id: user.id, create_time: last_week).count
      @last_week_posts = 1 if @last_week_posts == 0
      @receiver_ratio << (@this_week_posts.to_f / @last_week_posts.to_f) * 100
      return @receiver_ratio
    end
  end

  def giver_ranking(user)
    last_week =  Date.today.prev_week.beginning_of_week...Date.today.beginning_of_week
    this_week = Date.today.beginning_of_week...Date.today.next_week.beginning_of_week

    @giver_ratio =[]
    @this_week_posts = Post.where(company_id: @company.id, delete_flag: 0, user_id: user.id, create_time: this_week).count
    @giver_ratio << @this_week_posts

    if this_week.cover?(user.create_time)
      @giver_ratio << "-"
    else
      @last_week_posts = Post.where(company_id: @company.id, delete_flag: 0, user_id: user.id, create_time: last_week).count
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
    user_emails = User.where(company_id: @company.id, delete_flag: 0).pluck(:email)
    data = {
      user_emails: user_emails,
      subject: params[:subject],
      description: params[:description]
    }
    ReleaseArticleJob.new.async.perform(data)

    flash[:notice] = "メール配信が完了しました"
    redirect_to company_articles_path
  end

  def set_first_image(post)
    image = post.images.order("is_eye_catch desc, place_number asc").first
      
    @first_images[post.id] = ""
    if image.present?
      @first_images[post.id] = image[:img_src]
    end
  end
end
