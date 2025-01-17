#coding:utf-8
require 'securerandom'
require 'csv'

class CompanyController < ApplicationController
  before_filter :init, :authenticate_user, :except => [:login, :logout, :create, :create_complete, :forgot_password, :forgot_password_submit]
  before_filter :init_url, :validate_user
  before_action :ip_address_limit, :except => [:login, :logout, :create, :create_complete, :forgot_password, :forgot_password_submit]
  before_action :restrict_access_by_smartphone

  def init
    if session[:email].present? || cookies[:email].present?
      email = session[:email] || cookies[:email]
      user = User.find_by_email(email)
      unless user.nil?
        if user.admin == 1
          @id = user.company_id
          @user_id = user.id
        end
      else
        redirect_to "/logout"
      end
    else
      logout
    end
  end
  
  def login
    flash[:notice] = "" 
    if session[:id] || cookies[:id]
      redirect_to "/company/details"
    else
      redirect_to "/"
    end
  end

  def logout
    session[:id] = nil
    session[:email] = nil
    cookies.delete :id
    cookies.delete :email
    reset_session

    redirect_to '/login'
  end

  def index
    #do nothing
  end

  def create
    #do nothing
  end

  def create_complete
    begin
      params[:prizy_url] = @prizy_url + "/login"
      params[:hashtags] = hashtags_fix(params[:hashtags])

      company = Company.new
      company.save_record(params)

      user = User.new
      user.save_record({
        :email      => params[:email],
        :password   => params[:password],
        :img_src    => "https://#{@s3_bucket}.s3-ap-northeast-1.amazonaws.com/common/noimg_pc.png",
        :name      => params[:email].split("@")[0],
        :company_id => company.id,
        :out_points => 100000,
        :admin      => 1,
        :deliver_invite_mail => 3,
      })

      c_code = (Time.now.to_i).to_s + "_" + (company.id).to_s
      company.invite_link = @prizy_url + "/invite?c_code=" + c_code
      company.save

      if company.save
        CompanyMailer.welcome_email(params).deliver_later
          invite_link = InviteLink.new
          invite_link.save_record({
            :company_id   => company.id,
            :c_code  => c_code
          })
      end
      session[:id] = nil
      cookies.delete :id
      reset_session
    rescue Exception => e
      puts e.message
      # flash[:notice] = "メールアドレスはすでにありました"
      flash[:notice] = "#{e}"
      render 'create'
    end
  end

  def details 
    @company = Company.find(@id)
  end

  def edit
    @company = Company.find(@id)
  end

  def edit_complete
    params[:hashtags] = hashtags_fix(params[:hashtags])
    company = Company.find(@id)
    user = User.find_by_email(company.email).update(:email => params[:email])
    company.save_record(params)
    redirect_to "/company/details"
  end

  def hashtags_fix(hashtags)
    arr_hashtags = ""
    if hashtags.present?
      arr_hashtags = hashtags.split(",")
      arr_hashtags.reject! { | tag | tag.empty? }
      arr_hashtags.uniq!
      arr_hashtags.map{ | tag | tag.gsub(" ", "").strip }.compact.join(",")
    else
      # arr_hashtags="leadership,hardwork,creativity,positivity,teamwork"
      arr_hashtags = ""
    end
  end

  def customize
    @company = Company.find(@id)
    @nums = (0..10).map{|i| i*1 }
    @send_point_nums = (0..15).map{|i| i*1 }
  end

  def customize_update
    @company = Company.find(@id)
    @company.change_timeline_image_size = params[:change_timeline_image_size]
    @company.invite_email_flag = 0
    @company.point_fixed_flag = params[:fixed_point_setting]
    @company.give_point_to_sender_and_receiver_flag = params[:give_point_to_sender_and_receiver_setting]
    @company.fixed_point = params[:fixed_point].to_i
    @company.send_point = params[:give_point_to_sender].to_i
    @company.receive_point = params[:give_point_to_receiver].to_i
    @company.send_point_for_not_received = params[:send_point_for_not_received].to_i
    @company.send_point_for_not_received_flag = params[:send_point_for_not_received_flag].to_i
    @company.ip_limit_flag = params[:ip_address_setting]
    if params[:ip_address_setting].to_i == 1
      if params[:allowed_ips].empty?
        @company.allowed_ips = @ip
      else
        @company.allowed_ips = params[:allowed_ips]
      end
    end
    @company.reset_point_flag = params[:time_select]
    if params[:time_select].to_i == 1
      @company.reset_point_date = params[:reset_point_date]
    else
      @company.reset_point_date = ""
    end

    if @company.save
      redirect_to '/company/customize', notice: "変更を保存しました。"
    else
      if @company.fixed_point.integer? && @company.fixed_point.between?(0, 50)
      else
        @fixed_point = "0以上50以下のポイント数を設定してください。"
      end
      unless @company.send_point.integer? && @company.send_point.between?(0, 15) && @company.receive_point.integer? && @company.receive_point.between?(0, 15)
        @give_point_to_sender_and_receiver_setting = "1以上15以下のポイント数を設定してください。"
      end
      if @company.reset_point_flag == 1
        unless /\A\d{4}[\-]\d{2}[\-]\d{2}\z/ =~ @company.reset_point_date.to_s
          @reset_point_date = "xxxx/xx/xxの形式で入力してください。"
        end
      end
      if @company.ip_limit_flag == 1
        if @company.allowed_ips !~ /\A[\.\:\,\d]+\z/
          @allowed_ips = "IPアドレスに誤りがあります。"
        end
      end
      redirect_to '/company/customize', :flash => {:give_point_to_sender_and_receiver_setting => @give_point_to_sender_and_receiver_setting , :fixed_point => @fixed_point, :reset_point_date => @reset_point_date, allowed_ips: @allowed_ips}
    end
  end

  def confirm_invite_email_setting
    new_invite_email_setting = params[:invite_email_setting].to_i
    company= Company.find(current_user.company_id)
    if session[:error_not_match_invite_email_setting]
      company.invite_email_flag = params[:invite_email_setting].to_i
      company.save
      session.delete(:error_not_match_invite_email_setting)
      session.delete(:current_invite_email_setting)
      flash[:company_update] = "自動招待メール設定を変更しました"
      redirect_to :company_employees
    else
      if company.invite_email_flag == new_invite_email_setting
        session.delete(:current_invite_email_setting)
        redirect_to :company_employees
      else
        session[:error_not_match_invite_email_setting] = "自動招待メール設定が異なっています"
        redirect_to :company_employees_register
      end
    end
  end

  def employees
    @company = Company.find(@id)
    teams = Team.of_company(@id).available.order(sort: :asc)
    @departments = Department.of_company(@id).available.order(sort: :asc)
    # @manager_ids = Team.where(company_id: @id, delete_flag: 0).pluck(:manager_id)
    unless teams.empty?
      @team_exist = 0
      @teams = []
      teams.each do |team|
        team_members = []
        if team.member_ids.present?
          team.member_ids.split(",").each do |id|
            unless id.to_i == 0
            team_members << id.to_i
            end
          end
          each_team = {
            :team_id => team.id,
            :team_name => team.team_name,
            :members => team_members
          }
          @teams << each_team
        end
      end
      # 全社員のid取得
      user_ids = []
      User.of_company(@company.id).available.each do |user|
        user_ids << user.id
      end
      # 何かしらのチームに属してるid取得
      in_team_user_ids = []
      teams.each do |team|
        if team.member_ids.present?
          in_team_user_ids.push(team.member_ids.split(","))
          in_team_user_ids.push(team.manager_id)
          in_team_user_ids.flatten!
          in_team_user_ids.uniq
        end
      end
      # 何もチームに属していないid取得
      in_team_user_ids.each do |id|
        user_ids.delete(id.to_i)
      end
      # 何もチームに属していないユーザーの配列
      @non_team_user_ids = []
      user_ids.each do |id|
        @non_team_user_ids << id.to_i
      end
      # ハッシュ作成
      non_team = {
        :team_id => 0,
        :team_name => "所属なしユーザー",
        :members => @non_team_user_ids
      }
      @teams << non_team
      @search_type = params[:search_type]
      if @search_type == "email"
        @searched_users = User.where("email like '%" + params[:email] + "%'").of_company(@company.id).available
        @search_content = params[:email]
      elsif @search_type == "teams"
        if params[:team_selected_id] && params[:team_selected_id] != "00"
          @team_selected_id = params[:team_selected_id].to_i
          @selected_team = Team.available.of_company(@company.id).find(@team_selected_id)
          @selected_department = Department.available.of_company(@company.id).find(@selected_team.try(:department_id))
          @selected_department_child_teams = Team.of_company(@company.id).available.where(department_id: @selected_department.id)
        end
      end
    else
      @team_exist = 1
    end

    users = User.where(:company_id => @id, :delete_flag => 0)
    all_users = users.sort_by &:create_time
    users_count = all_users.count
    limit = 10
    page = params[:page] || 1
    @total_users = users_count
    @total_pages = (@total_users/limit.to_f).ceil
    if page.to_i <= 1
      page    = 1
      offset  = 0
    else
      offset  = (page.to_i * limit) - limit
    end
    all_users = all_users[offset, limit]
    @users     = User.available.of_company(@company.id).where(id: all_users.map(&:id)).order("id asc")
    @page_now = params[:page].to_i
    if @page_now == 0
      @page_now = 1
    end
    @previous_page  = @page_now - 1
    @next_page      = @page_now + 1
  end

  def register_employees
    @user = User.new
    @department = Department.new
    @departments = Department.available.of_company(@id).order(sort: :asc)
    @years = Util.years
    @b_year   = 0
    @b_month  = 0
    @b_day    = 0
  end

  def create_users_by_csv
    file = params[:user][:upload_file]
    if file
      company = Company.find(current_user.company_id)
      count_created_user_by_csv = 0
      User.transaction do
        count_created_user_by_csv = User.create_users_by_csv(file , current_user , company.invite_email_flag , count_created_user_by_csv)
      end
      if count_created_user_by_csv == 0
        flash[:notice_about_create_user] = "追加済みです"
        redirect_to '/company/employees/register'
      else
        flash[:notice_about_create_user] = "社員#{count_created_user_by_csv}名を追加しました"
        session[:current_invite_email_setting] = company.invite_email_flag
        redirect_to '/company/employees/register'
      end
    else
      flash[:notice_about_create_user] = "CSVファイルを選択してください"
      redirect_to '/company/employees/register'
    end
    # エラー時の処理
    rescue => e
    if e && /.+Shift_JIS+./ =~ e.to_s
      flash[:notice_about_create_user] = "文字化けしているデータがあります。"
    else
      flash[:notice_about_create_user] = "#{e}"
    end
    redirect_to '/company/employees/register'
  end

  def create_department_and_team_by_csv
    file = params[:department][:upload_file]
    if file
      Department.transaction do
        Department.create_department_and_team_by_csv(file , current_user)
      end
      flash[:notice] = "部署・チームを追加しました"
      redirect_to '/company/teams'
    else
      flash[:notice] = "CSVファイルを選択してください"
      redirect_to '/company/teams'
    end
    rescue => e
    flash[:notice] = "CSVファイルに空のセルはありませんか？もう一度送信をお願いいたします。"
    redirect_to '/company/teams'
  end

  # TODO Refactoring
  def export_csv_format_create_user
    company = Company.find(current_user.company_id)
    headers = %w(No lastname firstname email department team birthday gender)
    data = CSV.generate("", headers: headers ) do |csv|
      csv << headers
    end
    datetime = Time.now
    format_datetime = datetime.strftime('%Y_%m_%d_%H%M')
    send_data(data , filename:  "#{format_datetime}" + "社員登録フォーマット" + '.csv',type: 'csv')
  end

  def export_csv_format_create_department_and_team
    headers = %w(No department team)
    data = CSV.generate("", headers: headers ) do |csv|
      csv << headers
    end
    datetime = Time.now
    format_datetime = datetime.strftime('%Y%m%d%H%M%S')
    send_data(data , filename: "team" + "#{format_datetime}" + '.csv',type: 'csv')
  end

  def register_employees_complete
    ActiveRecord::Base.transaction do
      company = Company.find(@id)
      temp_password = SecureRandom.hex(4)
      salt = BCrypt::Engine.generate_salt

      name = params[:email].split("@")[0]
      b_year  = params[:b_year]
      b_month = params[:b_month]
      b_day   = params[:b_day]
      @data = {
        company_id: company.id,
        name: name,
        lastname: params[:lastname],
        firstname: params[:firstname],
        email: params[:email],
        salt: salt,
        password: BCrypt::Engine.hash_secret(temp_password, salt),
        gender: params[:gender].to_i,
        birthday: DateTime.parse("#{b_year}-#{b_month}-#{b_day}").strftime("%Y-%m-%d"),
        img_src: "https://#{@s3_bucket}.s3-ap-northeast-1.amazonaws.com/common/noimg_pc.png",
        prizy_url: @prizy_url + "/login"
      }
      @user = User.new
      if @user.save_record(@data)
        flash[:notice_about_create_user] = "社員を追加しました"
        # add_team
        if params[:team_id].present?
          team = Team.find(params[:team_id])
          if team
            team.member_ids = team.member_ids + "," + @user.id.to_s
            team.save
          end
        end
        data = {
          users: [@user]
        }
        DeliverInviteMailJob.new.async.perform(data)
        redirect_to "/company/employees/register"
      else
        flash[:notice_about_create_user] = "すでに登録しています"
        redirect_to "/company/employees/register"
      end
    end
    rescue => e
      flash[:error] = "#{e}"
      redirect_to "/company/employees/register"
  end

  def add_employees
    @company = Company.find(@id)
    redirect_to "/company/employees" if @company.invite_email_flag == 1
  end

  def add_employees_complete
    emails = params[:emails].split("\r\n")
    emails.map{ |s| s.strip }
    company = Company.find(@id)
    existing_emails = User.uniq.pluck(:email)
    @duplicate_emails = []

    emails.each do | email |
      if existing_emails.include?(email)
        @duplicate_emails << email
      else
        temp_password = SecureRandom.hex(4)
        name = email.split("@")[0]

        @data = {
          :company_id  => @id,
          :company_name  => company.name,
          :company_owner=> company.owner,
          :email  => email,
          :password  => temp_password,
          :name    => name,
          :img_src  => "https://#{@s3_bucket}.s3-ap-northeast-1.amazonaws.com/common/noimg_pc.png",
          :prizy_url  => @prizy_url + "/login"
        }
        @user = User.new
        @user.save_record(@data)
      end
    end

    if @duplicate_emails.present?
      redirect_to '/company/employees/add', notice: "#{@duplicate_emails.join(", ")} はすでに登録されています。"
      return
    end
    redirect_to "/company/employees"
  end

  def delete_employees 
    previous_page = request.referrer
    result = User.find(params[:id])
    manager_ids = Team.where(company_id: @id, delete_flag: 0).pluck(:manager_id)
    unless manager_ids.include?(result.id)
      result.delete_record
      redirect_to previous_page
    end
  end

  def rewards
    @rewards = Reward.where(:company_id => @id, :delete_flag => 0)
  end

  def add_rewards_complete
    params[:company_id] = @id
    params[:img_src] = @s3_url + "/common/img_01.png"
    @user = Reward.new
    if @user.save_record(params)
      redirect_to '/company/rewards'
    else
      redirect_to '/company/rewards/add', notice: "ポイント数に不備があります。"
    end
  end

  def edit_rewards
    @reward = Reward.find(params[:reward_id])
  end

  def edit_rewards_complete
    params[:company_id] = @id

    result = Reward.find(params[:reward_id])
    result.save_record(params)
    redirect_to '/company/rewards'
  end

  def delete_rewards 
    result =  Reward.find(params[:id])
    result.delete_record
    redirect_to '/company/employees'
  end

  def rewards_request
    @rewards = RequestReward.where(company_id: @id, status: 0, delete_flag: 0)
    @rewards_accepted = RequestReward.where(:company_id => @id, :status => 1).order("update_time desc")
    @rewards_rejected = RequestReward.where(:company_id => @id, :status => 9).order("update_time desc")
  end

  def rewards_request_action
    res = RequestReward.find(params[:id])
    params[:name] = res.user.name
    params[:email] = res.user.email
    params[:prizy_url] = @prizy_url + "/rewards/status#accepted"

    if res.delete_flag == 0
      if params[:status].to_i == 1 
        res.status = 1 #accept
        UserMailer.reward_approved_email(params).deliver_later
      elsif params[:status].to_i == 9 
        res.status = 9 #reject
      else
        res.status = 0 #pending
      end
      res.save
    end

    redirect_page("company","rewards_request")
  end

  def bonus 
    @bonus = Bonus.where(:company_id => @id, :delete_flag => 0)
  end

  def add_bonus_complete
    params[:company_id] = @id

    @bonus = Bonus.new
    @bonus.save_record(params)
    redirect_to '/company/bonus'
  end

  def edit_bonus
    @bonus = Bonus.find(params[:bonus_id])
  end

  def edit_bonus_complete
    params[:company_id] = @id

    result = Bonus.find(params[:bonus_id])
    result.save_record(params)
    redirect_to '/company/bonus'
  end

  def delete_bonus
    result =  Bonus.find(params[:id])
    result.delete_record
    redirect_to '/company/bonus'
  end

  def make_manager
    result =  User.find(params[:id])
    result.manager_flag = 1
    result.save

    redirect_to '/company/employees'
  end

  def make_non_manager
    result =  User.find(params[:id])
    result.manager_flag = 0
    result.save

    redirect_to '/company/employees'
  end

  def make_admin
    result =  User.find(params[:id])
    result.admin = 1
    result.save

    redirect_to '/company/employees'
  end

  def make_user
    result =  User.find(params[:id])
    result.admin = 0
    result.save
    
    redirect_to '/company/employees'
  end

  def redirect_to_index
    redirect_to "/company/details" 
  end

  def ip_address_limit
    @company = Company.find(@id)
    @ip = request.remote_ip
    allowed_ips = @company.allowed_ips.split(",") if @company.allowed_ips.present?
    if @company.ip_limit_flag == 1
    unless allowed_ips.include?(@ip.to_s)
      redirect_to "/"
    end
    end
  end

  def self.reset_point
    reset_date = Date.yesterday
    company_ids = Company.where(reset_point_flag: 1).where(reset_point_date: reset_date).pluck(:id)
    company_ids.each do |id|
      users = User.where(company_id: id)
      users.update_all(in_points: 0)
      users.update_all(out_points: 0)
    end
  end

  def edit_email
    @user = User.find(params[:id])
    render :json => {:id => @user.id , :name => @user.name , :email => @user.email}
  end

  def update_email
    @company = Company.find(@id)
    owner_email = @company.email
    if params[:user_id]
      @user = User.find(params[:user_id])
      if @user
        emails = User.where(company_id: @id, delete_flag: 0).pluck(:email)
        if emails.include?(params[:user][:email])
          redirect_to '/company/employees', notice: "すでに登録されているメールアドレスです。"
          return
        else
          if owner_email == @user.email
            @company.email = params[:user][:email]
            @company.save
          end
          @user.email = params[:user][:email]
          @user.save
        end
      end
    end
    redirect_to '/company/employees'
  end

  def teams 
    @managers = User.where(:company_id => @id, :delete_flag => 0, :manager_flag => 1)
    @departments = Department.where(:company_id => @id, :delete_flag => 0).order(sort: :asc)
    @department = Department.new
    teams = Team.where(:company_id => @id, :delete_flag => 0).order(sort: :asc)
    all_teams = teams.sort_by &:create_time
    teams_count = all_teams.count
    limit = 10
    page = params[:page] || 1
    @total_teams = teams_count
    @total_pages = (@total_teams/limit.to_f).ceil
    if page.to_i <= 1
      page    = 1
      offset  = 0
    else
      offset  = (page.to_i * limit) - limit
    end
    all_teams = all_teams[offset, limit]
    @teams     = Team.where(id: all_teams.map(&:id)).order(sort: :asc)
    @page_now = params[:page].to_i
    if @page_now == 0
      @page_now = 1
    end
    @previous_page  = @page_now - 1
    @next_page      = @page_now + 1
  end

  # def team_show
  #   @team = Team.find(params[:id])
  #   unless @team.company_id == @id
  #     redirect_to "/company/teams"
  #   end
  #   # @manager_ids = Team.where(company_id: @id, delete_flag: 0).pluck(:manager_id)
  #   user_ids = []
  #   if @team.member_ids.present?
  #     @team.member_ids.split(",").each do |id|
  #       user_ids << id.to_i
  #     end
  #   end
  #   users = User.where(:id => user_ids, :company_id => @id, :delete_flag => 0)
  #   all_users = users.sort_by &:create_time
  #   users_count = all_users.count
  #   limit = 20
  #   page = params[:page] || 1
  #   @total_users = users_count
  #   @total_pages = (@total_users/limit.to_f).ceil
  #   if page.to_i <= 1
  #     page    = 1
  #     offset  = 0
  #   else
  #     offset  = (page.to_i * limit) - limit
  #   end
  #   all_users = all_users[offset, limit]
  #   @users     = User.where(id: all_users.map(&:id)).order("id asc")
  #   @page_now = params[:page].to_i
  #   if @page_now == 0
  #     @page_now = 1
  #   end
  #   @previous_page  = @page_now - 1
  #   @next_page      = @page_now + 1
  # end

  # def add_teams_complete
  #   params[:company_id] = @id
  #   team_names = Team.where(company_id: @id, department_id: params[:department_id].to_i ,delete_flag: 0).pluck(:team_name)
  #   if team_names.include?(params[:team_name])
  #     redirect_to "/company/teams", notice: "そのチーム名はすでに登録されています。"
  #     return
  #   end
  #   @member_ids = []
  #   if params[:members].reject(&:blank?).blank?
  #     redirect_to "/company/teams", notice: "少なくとも一人以上の社員を登録してください"
  #     return
  #   end
  #   members = params[:members].delete_if{|n| n.empty? }
  #   members.each do |mem|
  #     user = User.find_by(email: mem, delete_flag: 0)
  #     if user.present?
  #       @member_ids << user.id.to_s
  #     else
  #       redirect_to "/company/teams", notice: "登録できませんでした。メールアドレスが一致しません。"
  #       return
  #     end
  #   end
  #   @member_ids.uniq!
  #   params[:member_ids] = @member_ids.join(",")
  #   @user = Team.new
  #   @user.save_record(params)
  #   redirect_to '/company/teams', notice: "登録が完了しました。"
  # end

  # def edit_teams
  #   @users = User.where(company_id: @id, delete_flag: 0)
  #   @emails = []
  #   @users.each do |user|
  #     @emails << user.email
  #   end
  #   @team = Team.find(params[:team_id])
  #   if @team.company_id == @id
  #     @managers = User.where(:company_id => @id, :delete_flag => 0, :manager_flag => 1)
  #     @departments = Department.where(:company_id => @id, :delete_flag => 0)
  #     @members = []
  #     if @team.member_ids.present?
  #       @team.member_ids.split(",").each do |mem|
  #         unless mem.to_i == 0
  #           @members << User.find_by(id: mem.to_i, delete_flag: 0)
  #         end
  #       end
  #     end
  #   else
  #     redirect_to '/company/teams'
  #   end
  # end

  # def edit_teams_complete
  #   @team = Team.find(params[:team_id])
  #   if @team.company_id == @id
  #     @member_ids = []
  #     if params[:members].reject(&:blank?).blank?
  #       redirect_to "/company/teams/edit/#{@team.id}", notice: "少なくとも一人以上の社員を登録してください。"
  #       return
  #     end
  #     members = params[:members].delete_if{|n| n.empty? }
  #     members.each do |mem|
  #       user = User.find_by(email: mem, delete_flag: 0)
  #       if user.present?
  #         @member_ids << user.id.to_s
  #       else
  #         redirect_to "/company/teams/edit/#{@team.id}", notice: "登録できませんでした。メールアドレスが一致しません。"
  #         return
  #       end
  #     end
  #     @member_ids.uniq!
  #     params[:member_ids] = @member_ids.join(",")
  #     @team.save_record(params)
  #     redirect_to '/company/teams'
  #   else
  #     redirect_to '/company/teams'
  #   end
  # end

  # def delete_teams
  #   result =  Team.find(params[:id])
  #   result.delete_record
  #   redirect_to '/company/teams'
  # end

  # def add_departments_complete
  #   params[:company_id] = @id

  #   @department = Department.new
  #   @department.save_record(params)
  #   redirect_to '/company/teams'
  # end

  # def edit_departments
  #   @department = Department.find(params[:id])
  #   render :json => {:dep_id => @department.id , :name => @department.dep_name}
  # end

  # def edit_departments_complete
  #   @department = Department.find(params[:dep_id].to_i)
  #   @department.dep_name = params[:dep_name]
  #   @department.save
  #   redirect_to '/company/teams'
  # end

  # def delete_departments
  #   result =  Department.find(params[:id])
  #   result.delete_record
  #   redirect_to '/company/teams'
  # end
end
