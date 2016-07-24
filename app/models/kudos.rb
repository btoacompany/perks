#coding:utf-8

class Kudos < ActiveRecord::Base
  self.table_name = "kudos"

  belongs_to :user, :class_name => 'User'
  belongs_to :receiver, :class_name => 'User'
  belongs_to :posts

  before_create :set_create_time
  before_update :set_update_time

  def save_record(params)
    self.user_id	= params[:user_id]
    self.post_id	= params[:post_id]
    self.kudos		= params[:kudos]
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
