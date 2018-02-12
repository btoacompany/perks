#coding:utf-8

class Pv < ActiveRecord::Base
  self.table_name = "pv"

  before_create :set_create_time

  def save_record(params)
    self.company_id	 = params[:company_id]
    self.user_id	   = params[:user_id]
    self.team_id	   = params[:team_id]
    self.page_path	 = params[:page_path]
    self.pv_count    = params[:pv_count]
    self.track_date  = params[:track_date]
    self.save
  end

  def set_create_time 
    t = set_time
    self.create_time = t
  end

  def set_time
    return Time.now.strftime("%Y-%m-%d %H:%M:%S")
  end
end
