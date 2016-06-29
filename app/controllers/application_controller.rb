require 'ostruct'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session,
    if: Proc.new { |c| c.request.format =~ %r{application/json} }
  helper_method :current_user

  def current_user
    if session[:admin_id]
      @current_user||= Admin.find(session[:admin_id])
    elsif session[:user_id]
      @current_user||= User.find(session[:user_id])
    elsif session[:company_id]
      @current_user||= Company.find(session[:company_id])
    end

    if @current_user
      @current_user
    else
      OpenStruct.new(name: "Guest")
    end
  end

protected 
  def authenticate_admin
    if session[:admin_id]
      # set current admin object to @current_user object variable
      @current_user = Admin.find(session[:admin_id])
      return true	
    else
      redirect_to "/tools/login"
      return false
    end
  end

  def authenticate_user
    if session[:user_id]
      # set current user object to @current_user object variable
      @current_user = User.find(session[:user_id])
      return true	
    else
      redirect_to "/login"
      return false
    end
  end

  def authenticate_company
    if session[:company_id]
      # set current user object to @current_user object variable
      @current_user = Company.find(session[:company_id])
      return true	
    else
      redirect_to "/company/login"
      return false
    end
  end

  def save_login_state
    if session[:admin_id]
      redirect_to(:controller => 'logs', :action => 'index')
      return false
    elsif session[:user_id]
      redirect_to(:controller => 'perks', :action => 'index')
      return false
    elsif session[:company_id]
      redirect_to(:controller => 'top', :action => 'index')
      return false
    else
      return true
    end
  end
end
