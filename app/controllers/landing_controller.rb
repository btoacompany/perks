class LandingController < ApplicationController

  before_filter :init, :except => [:slack, :privacy, :terms, :contact, :contact_mail]
  before_filter :user_login, :only => [:slack, :privacy, :terms, :contact, :contact_mail]
  before_filter :init_url

  def init
    if session[:id].present? || cookies[:id].present?
      redirect_to '/user'
    end
  end

  def user_login
    if session[:id].present? || cookies[:id].present?
      @user_login = 1
    else
      @user_login = 0
    end
  end

  def index
  end

  def price
  end

  def slack
  end

  def privacy
  end

  def terms
  end

  def contact
  end

  def contact_mail
    @company = params[:company]
    @name = params[:name]
    @email = params[:email]
    @text = params[:text]
    ContactMailer.contact_mail(@company, @name, @email, @text).deliver
    ContactMailer.btoa_mail(@company, @name, @email, @text).deliver
    redirect_to '/contact'
  end


end
