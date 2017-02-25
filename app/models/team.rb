#coding:utf-8

class Team < ActiveRecord::Base
  self.table_name = "teams"

  before_create :set_create_time
  before_update :set_update_time

  def save_record(params)
    self.department_id	= params[:department_id]
    self.team_name	= params[:team_name]
    self.company_id	= params[:company_id]
    self.manager_id	= params[:manager_id]
    self.member_ids	= params[:member_ids]
    self.save
  end
  
  def delete_record
    self.delete_flag = 1
    self.save
  end

  def set_create_time 
    t = set_time
    self.create_time = t
    self.update_time = t
  end

  def set_update_time 
    t = set_time
    self.update_time = t
  end

  def set_time
    return Time.now.strftime("%Y-%m-%d %H:%M:%S")
  end
end