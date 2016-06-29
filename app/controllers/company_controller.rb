#coding:utf-8
require 'securerandom'

class CompanyController < ApplicationController
  before_filter :init, :authenticate_company, :except => [:login, :login_complete, :logout, :create, :create_complete]

  def init
    @id = session[:company_id] if session[:company_id].present? 
  end

  def login
    if session[:company_id]
      @id = session[:id]
      redirect_to "/company"
    end
  end

  def login_complete
    authorized_user = Company.authenticate(params[:email],params[:password])
    reset_session
    if authorized_user
      session[:company_id] = authorized_user.id
      flash[:notice] = "" 
      redirect_to "/company"
    else
      flash[:notice] = "Invalid Username or Password"
      flash[:color]= "invalid"
      render "login"
    end
  end

  def logout
    session[:company_id] = nil
    reset_session
    redirect_to '/company/login'
  end

  def index
    #do nothing
  end

  def create
    #do nothing
  end

  def create_complete
    res = Company.new
    res.save_record(params)
    session[:id] = res.id
    redirect_to_index
  end

  def details 
    @company = Company.find(@id)
  end

  def edit
    @company = Company.find(@id)
  end

  def edit_complete
    res = Company.find(@id)
    res.save_record(params)

    if params[:password].present?
      redirect_to '/company/logout'
    else
      redirect_to_index
    end
  end

  def employees
    @users = User.where(:company_id => @id, :delete_flag => 0)
  end

  def add_employees
    #do nothing
  end

  def add_employees_complete
    emails = params[:emails].split("\r\n")
    emails.map{ |s| s.strip }

    emails.each do | email |
      temp_password = SecureRandom.hex(4)
      name = email.split("@")[0]

      @data = {
	:company_id	=> @id,
	:company_name	=> Company.find(@id).name,
	:email		=> email,
	:password	=> temp_password,
	:name		=> name
      }

      @user = User.new
      @user.save_record(@data)

      respond_to do |format|
	if @user.save
	  # Tell the UserMailer to send a welcome email after save
	  UserMailer.verify_account(@data).deliver_now
	  format.html { }
	  format.json { render json: @user, status: :created, location: @user }
	else
	  format.html { render action: 'new' }
	  format.json { render json: @user.errors, status: :unprocessable_entity }
	end
      end
    end

    redirect_to "/company/employees"
  end

  def remove_employees
    res = User.find(@id)
    res.delete_record
    redirect_to_index 
  end

  def redirect_to_index
    redirect_to "/company" 
  end
end
