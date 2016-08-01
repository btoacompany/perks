#coding:utf-8

class Reward < ActiveRecord::Base
  self.table_name = "rewards"
  belongs_to :company

  before_create :set_create_time
  before_update :set_update_time

  def save_record(params)
    if params[:img_src].present?
      self.img_src	= params[:img_src]
    end

    self.title		= params[:title]
    self.company_id	= params[:company_id]
    self.description	= params[:description]
    self.points		= params[:points]
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
