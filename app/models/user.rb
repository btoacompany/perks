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
  has_many :article_likes
  has_many :articles, through: :article_likes
  has_many :tags
  has_many :articles, through: :tags
  has_many :user_posted_contents

  before_save 	:encrypt_password
  after_save 	:clear_password
  before_create :set_create_time
  before_update :set_update_time

  validates :email, uniqueness: true

  # validate :check_maneger

  def self.koala(auth)
    access_token = auth['token']
    facebook = Koala::Facebook::API.new(access_token)
    facebook.get_object("me?fields=id,first_name,last_name,gender,name,picture")
  end

  def self.autocomplete_suggestions(company_id)
    @user_ids = Array.new
    @user_fullnames = Array.new
    users = User.where(company_id: company_id)
    users.each do |user|
      if user.lastname && user.firstname
        fullname = user.lastname + user.firstname
        @user_ids.push(user.id)
        @user_fullnames.push(fullname)
      end
    end
    return @user_ids, @user_fullnames
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
  def self.create_users_by_csv(file , current_user , invite_email_flag , count_created_user_by_csv)
    CSV.foreach(file.path , encoding: "Shift_JIS:UTF-8" , headers: true ) do |row_data|
      check_registered_user = User.find_by(email: row_data["email"])
      unless  check_registered_user
        user = User.new
        user.firstname = row_data["firstname"]
        user.lastname = row_data["lastname"]
        user.name = row_data["lastname"].to_s + row_data["firstname"].to_s
        user.email = row_data["email"]
        user.verified = 1
        user.password = SecureRandom.hex(4)
        user.salt = BCrypt::Engine.generate_salt
        user.password = BCrypt::Engine.hash_secret(user.password, user.salt)
        user.company_id = current_user.company_id
        user.birthday = row_data["birthday"] if row_data["birthday"]
        user.img_src = "//btoa-img.s3-ap-northeast-1.amazonaws.com/common/noimg_pc.png"
        row_data["gender"] === "1" ? user.gender = 1 : user.gender = 0
        user.save!
        count_created_user_by_csv += 1 if user.save
        # add user to team
        check_department = Department.find_by(dep_name: row_data["department"])
        unless check_department
          check_department = Department.new
          check_department.dep_name = row_data["department"]
          check_department.company_id = current_user.company_id
          check_department.save!
        end
        check_team = Team.find_by(team_name: row_data["team"] , department_id: check_department.id)
        if check_department && check_team
          check_team.member_ids = check_team.member_ids + "," + user.id.to_s
          check_team.save!
        end
      end
    end
    return count_created_user_by_csv
  end

  def check_maneger
    if manager_flag == 0
      team = Team.find_by(manager_id: id)
      if team
        errors.add(manager_flag, :invalid)
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
