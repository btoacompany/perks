require 'ostruct'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session,
    if: Proc.new { |c| c.request.format =~ %r{application/json} }
  helper_method :current_user

  def init_url
    if Rails.env.production?
      @prizy_url = "http://prizy.me"
      @s3_url = "https://s3-ap-northeast-1.amazonaws.com/prizy"
      @s3_bucket = "prizy"
    elsif Rails.env.development?
      @prizy_url = "http://localhost:3000"
      @s3_url = "https://s3-ap-northeast-1.amazonaws.com/btoa-img"
      @s3_bucket = "btoa-img"
    end
  end

  def validate_user
    if @current_user.present?
      unless @current_user.admin == 1
	redirect_to "/"
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


protected 
  def authenticate_user
    user_id = session[:id] || cookies[:id]
    if user_id
      # set current user object to @current_user object variable
      @current_user = User.find(user_id)
      return true	
    else
      redirect_to "/login"
      return false
    end
  end

  def save_login_state
    if session[:id] || cookies[:id]
      redirect_to(:controller => 'top', :action => 'index')
      return false
    else
      return true
    end
  end
end
