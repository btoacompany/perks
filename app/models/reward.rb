#coding:utf-8

class Reward < ActiveRecord::Base
  self.table_name = "rewards "

  before_create :set_create_time
  before_update :set_update_time

  def save_record(params)
    self.name		= params[:name]
    self.img_src	= params[:img_src]
    self.url		= params[:url]
    self.category_id	= params[:category_id]
    self.description	= params[:description]
    self.vendor_id	= params[:vendor_id]
    self.vendor_name	= params[:vendor_name]
    self.price		= params[:price]
    self.discount	= params[:discount]
    self.sale_price	= params[:sale_price]
    self.plan		= params[:plan] 
    self.status		= 0 
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
