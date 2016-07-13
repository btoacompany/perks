#coding:utf-8

class Post < ActiveRecord::Base
  self.table_name = "posts"

  belongs_to :user, :class_name => 'User'
  belongs_to :receiver, :class_name => 'User'
  belongs_to :company
  has_many :comments
  has_many :kudos
  has_many :hashtags

  before_create :set_create_time
  before_update :set_update_time

  def save_record(params)
    self.company_id	= params[:company_id]
    self.user_id	= params[:user_id]
    self.receiver_id	= params[:receiver_id]
    self.points		= params[:points]
    self.description	= params[:description]
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
