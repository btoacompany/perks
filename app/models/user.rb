#coding:utf-8
require 'bcrypt'

class User < ActiveRecord::Base
  include BCrypt

  serialize :accounts
  self.table_name = "users"

  belongs_to :company
  has_many :posts
  has_many :comments
  has_many :kudos
  has_many :hashtags

  before_save 	:encrypt_password
  after_save 	:clear_password
  before_create :set_create_time
  before_update :set_update_time

  def self.koala(auth)
    access_token = auth['token']
    facebook = Koala::Facebook::API.new(access_token)
    facebook.get_object("me?fields=id,first_name,last_name,gender,name,picture")
  end
  
  def save_record(params)
    @password = params[:password]
    
    if params[:img_src].present?
      self.img_src	= params[:img_src]
    end
    
    self.name	      = params[:name]	      if params[:name].present?
    self.email	      = params[:email]	      if params[:email].present?
    self.company_id   = params[:company_id]   if params[:company_id].present?
    self.firstname    = params[:firstname]
    self.lastname     = params[:lastname]
    self.birthday     = params[:birthday]
    self.job_title    = params[:job_title]
    self.gender	      = params[:gender]	 || 0
    self.in_points    = params[:in_points]    if params[:in_points].present?
    self.out_points   = params[:out_points]   if params[:out_points].present?
    self.verified     = params[:verified]     if params[:verified].present?
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

  def encrypt_password
    if @password.present?
      self.salt = BCrypt::Engine.generate_salt
      self.password = BCrypt::Engine.hash_secret(@password, salt)
    end
  end

  def clear_password
    @password = nil
  end

  def match_password(login_password="")
    password == BCrypt::Engine.hash_secret(login_password, salt)
  end

private
  def self.authenticate(email="", login_password="")
    user = User.find_by_email(email)

    if user && user.match_password(login_password)
      return user 
    else
      return false
    end
  end   
end
