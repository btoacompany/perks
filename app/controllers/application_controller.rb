require 'ostruct'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session,
    if: Proc.new { |c| c.request.format =~ %r{application/json} }
  helper_method :current_user

  def init_url
    @slack_webhooks = "https://hooks.slack.com/services/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"
    @protocol = "http://"
    if Rails.env.production?
      @prizy_url = "http://prizy.me"
      @s3_url = "https://s3-ap-northeast-1.amazonaws.com/prizy"
      @s3_bucket = "prizy"
      
      sub_domain = request.subdomain
      if sub_domain == "www"
	@protocol = "https://"
      end
    elsif Rails.env.development?
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
