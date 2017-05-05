class LandingController < ApplicationController

  before_filter :init, :except => [:slack, :privacy, :terms, :contact, :contact_mail]
  before_filter :user_login, :only => [:slack, :privacy, :terms, :contact, :contact_mail]
  # before_filter :init_url

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

  def slack_add
  end

  def index
  end

  def price
  end

  def slack
    user_id = session[:id] || cookies[:id]
    if user_id
      # set current user object to @current_user object variable
      @current_user = User.find(user_id)
      return true 
    end
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
    redirect_to '/contact', notice: "お問い合わせいただきありがとうございます。内容を確認し、3営業日以内にご連絡いたします。"
  end

end
