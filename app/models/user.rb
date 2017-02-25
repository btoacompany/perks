#coding:utf-8
require 'bcrypt'
require 'csv'

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
    self.firstname    = params[:firstname]    if params[:firstname].present?
    self.lastname     = params[:lastname]     if params[:lastname].present?
    self.birthday     = params[:birthday]     if params[:birthday].present?
    self.job_title    = params[:job_title]    if params[:job_title].present?
    self.gender	      = params[:gender]	      if params[:gender].present?
    self.in_points    = params[:in_points]    if params[:in_points].present?
    self.out_points   = params[:out_points]   if params[:out_points].present?
    self.verified     = params[:verified]     if params[:verified].present?
    self.admin	      = params[:admin]	      if params[:admin].present?
    self.manager_flag = params[:manager_flag] if params[:manager_flag].present?
    self.member_flag  = params[:member_flag]  if params[:member_flag].present?
    self.deliver_invite_mail = params[:deliver_invite_mail]  if params[:deliver_invite_mail].present?
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

  # 社員をCSVファイルで読み込み保存する
  def self.import_users_by_csv(file , current_user)
    CSV.foreach(file.path , headers: true) do |row_data|
      check_registered_user = User.find_by(email: row_data["email"])
      unless  check_registered_user
        user = User.new
        user.firstname = row_data["firstname"]
        user.lastname = row_data["lastname"]
        user.name = row_data["firstname"].to_s + row_data["lastname"].to_s
        user.email = row_data["email"]
        if row_data["password"]
          user.verified = 1
          user.password = row_data["password"]
        else
          user.verified = 0
          user.password = SecureRandom.hex(4)
        end
        user.company_id = current_user.company_id
        user.birthday = row_data["birthday"]
        row_data["gender"] === "男" ? user.gender = 1 : user.gender = 0
        user.save!
        # add user to team
        check_department = Department.find_by(dep_name: row_data["department"])
        check_team = Team.find_by(team_name: row_data["team"])
        if check_department && check_team
          check_team.manager_id = user.id if row_data["manager"] === "1"
          check_team.member_ids = check_team.member_ids + "," + user.id.to_s
          check_team.save!
        else
          logger.debug("user.name")
        end
      end
    end
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
