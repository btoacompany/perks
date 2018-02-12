#coding:utf-8

class TrackingController < ApplicationController
	before_filter :init, :authenticate_user

	def init
	    if session[:email].present? || cookies[:email].present?
	      	email = session[:email] || cookies[:email]
	      	@user = User.find_by_email(email)

	      	if @user.admin == 1
	        	@company = Company.find(@user.company_id)
	      	else
	        	redirect_to "/user"
	      	end
	    else
	      	logout
	    end
	end

	def track_pv
		date = Date.today

		data = {
			:company_id	=> @company.id,
			:user_id	=> @user.id,
			:team_id	=> 0,
			:page_path	=> params[:page_path],
			:pv_count	=> 1,
			:track_date	=> date
		}

		pv = Pv.new
		pv.save_record(data)

	end
end