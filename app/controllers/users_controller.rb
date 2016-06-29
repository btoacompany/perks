#coding:utf-8
require 'util.rb'

class UsersController < ApplicationController
  before_filter :init, :authenticate_user, :except => [:login, :login_complete, :logout]

  def init
    @id = session[:user_id] if session[:user_id].present? 
  end

  def login
    if session[:user_id]
      redirect_to "/"
    end
  end

  def login_complete
    authorized_user = User.authenticate(params[:email],params[:password])
    reset_session
    if authorized_user
      session[:user_id] = authorized_user.id

      verified = authorized_user.verified
      flash[:notice] = "" 

      if verified == 0
	redirect_to "/update"
      else
	redirect_to "/"
      end
    else
      flash[:notice] = "Invalid Email or Password"
      flash[:color]= "invalid"
      render "login"
    end
  end

  def logout
    session[:user_id] = nil
    reset_session
    redirect_to '/login'
  end

  def index
  end

  def update 
    @user = User.find(@id)
    @years = Util.years
  end

  def update_complete 
    b_year = params[:b_year]
    b_month = params[:b_month]
    b_day = params[:b_day]
    params[:birthday] = DateTime.parse("#{b_year}-#{b_month}-#{b_day}").strftime("%Y-%m-%d") 

    res = User.find(@id)
    res.save_record(params)
    redirect_to_index
  end

  def redirect_to_index
    redirect_to "/" 
  end
end
