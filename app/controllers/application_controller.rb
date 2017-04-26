require 'ostruct'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session,
    if: Proc.new { |c| c.request.format =~ %r{application/json} }
  helper_method :current_userz

  before_filter :init_url

# セプテーニのcompany_idをいれる。今は暫定
  $showoff_timeline = [1,2,3,32,30,79]
  $showoff_ranking = [1,2,3,32,30,79]
  $showoff_hashtag = [1,2,3,32,30,79]
  $ban_edit_name = [1,2,3,32,30,79]
  $allow_nickname = [1,2,3,32,30,79]
  $use_select = [1,2,3,32,30,79]
  $no_manager = [1,2,3,32,30,79]
  $nicknames = {
    1 => "同僚さん",
    2 => "白パンさん",
    3 => "ほしがりさん",
    4 => "匿名希望さん",
    5 => "のんべえさん",
    6 => "太鼓持ちさん",
    7 => "ベテランさん",
    8 => "メガネさん",
    9 => "ツーブロックさん",
    10 => "同期さん",
    11 => "パイセンさん",
    12 => "仕事ざっくりさん",
    13 => "おっさん",
    14 => "感謝でいっぱいさん",
    15 => "伊達男さん",
    16 => "タレントさん",
    17 => "とと姉さん",
    18 => "新潟コシヒカリ魚沼さん",
    19 => "クロワッさん"
  }

  def init_url
    #@slack_webhooks = "https://hooks.slack.com/services/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"
    if Rails.env.production?
      @protocol = "https://"
      @prizy_url = "https://www.prizy.me"
      @s3_url = "https://s3-ap-northeast-1.amazonaws.com/prizy"
      @s3_bucket = "prizy"      
    elsif Rails.env.development?
      @protocol = "http://"
      @prizy_url = "http://localhost:3000"
      @s3_url = "https://s3-ap-northeast-1.amazonaws.com/btoa-img"
      @s3_bucket = "btoa-img"
    end
  end

  def validate_user
    if @current_user.present?
      unless @current_user.admin == 1
	#redirect_to "/"
	redirect_page("users", "index")
      end
    end
  end

  def current_user
    user_id = session[:id] || cookies[:id]

    if user_id 
      @current_user||= User.find(user_id)
    end

    if @current_user
      @current_user
    else
      OpenStruct.new(name: "Guest")
    end
  end

  def restrict_access_by_smartphone
    user_agent = request.env["HTTP_USER_AGENT"]
    if(user_agent.include?('Mobile') || user_agent.include?('Android'))
      redirect_to  :controller => "users" , :action  => :index
    end
  end

  def redirect_page(controller, action)
    redirect_to :protocol => @protocol, :controller => controller, :action => action
  end
protected 
  def authenticate_user
    user_id = session[:id] || cookies[:id]
    if user_id
      # set current user object to @current_user object variable
      @current_user = User.find(user_id)
      return true	
    else
      redirect_page("users", "login")
      #redirect_to "/login", :protocol => @protocol
      return false
    end
  end

  def save_login_state
    if session[:id] || cookies[:id]
      redirect_page("users", "index")
      #redirect_to(:controller => 'top', :action => 'index', :protocol => @protocol)
      return false
    else
      return true
    end
  end
end
