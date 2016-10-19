class LandingController < ApplicationController

  before_filter :init

  def init
    if session[:id].present? || cookies[:id].present?
      redirect_to '/user'
    end
  end

  def index
  end


end
