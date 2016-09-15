#coding:utf-8

class Company < ActiveRecord::Base
  self.table_name = "company"

  has_many :users
  has_many :rewards
  has_many :posts

  before_create :set_create_time
  before_update :set_update_time
  
  def save_record(params)
    self.name	      = params[:name]	      if params[:name].present?
    self.owner	      = params[:owner]	      if params[:owner].present?
    self.email	      = params[:email]	      if params[:email].present?
    self.address      = params[:address]      if params[:address].present?
    self.phone	      = params[:phone]	      if params[:phone].present?
    self.url	      = params[:url]	      if params[:url].present?
    self.hashtags     = params[:hashtags]     if params[:hashtags].present?
    self.invite_link  = params[:invite_link]  if params[:invite_link].present?
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
