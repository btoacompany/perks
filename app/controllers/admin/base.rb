class Admin::Base < ApplicationController
  before_filter :init, :authenticate_user
  before_filter :init_url, :validate_user

  def init
    if session[:email].present? || cookies[:email].present?
      email = session[:email] || cookies[:email]
      @user = User.find_by_email(email)
      if @user && @user.admin == 1
        @company = Company.find(@user.company_id)
      else
        redirect_to "/logout"
      end
    else
      logout
    end
  end
end
