#coding:utf-8

class RequestReward < ActiveRecord::Base
  self.table_name = "request_rewards"

  belongs_to :company
  belongs_to :user, :class_name => 'User'
  belongs_to :reward, :class_name => 'Reward'

  before_create :set_create_time
  before_update :set_update_time

  def save_record(params)
    self.company_id   = params[:company_id]
    self.user_id      = params[:user_id]
    self.reward_id    = params[:reward_id]
    self.status	      = params[:status]
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
