require 'ostruct'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session,
    if: Proc.new { |c| c.request.format =~ %r{application/json} }
  helper_method :current_user

  def init_url
    @s3_url = "https://s3-ap-northeast-1.amazonaws.com/btoa-img"
    if Rails.env.production?
      @prizy_url = "http://prizy.me"
    elsif Rails.env.development?
      @prizy_url = "http://localhost:3000"
    end
  end

  def current_user
    user_id = session[:user_id] || cookies[:user_id]
    company_id = session[:company_id] || cookies[:company_id]

    if user_id 
      @current_user||= User.find(user_id)
    elsif company_id
      @current_user||= Company.find(company_id)
    end

    if @current_user
      @current_user
    else
      OpenStruct.new(name: "Guest")
    end
  end

protected 
  def authenticate_user
    user_id = session[:user_id] || cookies[:user_id]
    if user_id
      # set current user object to @current_user object variable
      @current_user = User.find(user_id)
      return true	
    else
      redirect_to "/login"
      return false
    end
  end

  def authenticate_company
    company_id = session[:company_id] || cookies[:company_id]
    if company_id
      # set current user object to @current_user object variable
      @current_user = Company.find(company_id)
      return true	
    else
      redirect_to "/company/login"
      return false
    end
  end

  def save_login_state
    if session[:user_id] || cookies[:user_id]
      redirect_to(:controller => 'top', :action => 'index')
      return false
    elsif session[:company_id] || cookies[:company_id]
      redirect_to(:controller => 'company', :action => 'index')
      return false
    else
      return true
    end
  end
end
