require 'ostruct'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session,
    if: Proc.new { |c| c.request.format =~ %r{application/json} }
  helper_method :current_user

# セプテーニのcompany_idをいれる。今は暫定
  begin
    all_company_ids = Company.all.where(delete_flag: 0).pluck(:id)
  rescue ActiveRecord::StatementInvalid => e
    Rails.logger.error(e)
    Rails.logger.error(e.backtrace)
    all_company_ids = []
  end
  $showoff_timeline = all_company_ids
  $showoff_ranking  = all_company_ids
  $showoff_hashtag  = all_company_ids
  $ban_edit_name    = all_company_ids
  $allow_nickname   = [1, 3, 32, 14]
  $use_select       = all_company_ids
  $no_manager       = all_company_ids
  $use_timeline     = [14, 115, 27, 143]

  $nicknames = {
    1 => "同僚さん",
    2 => "白パンさん",
    3 => "ほしがりさん",
    4 => "匿名希望さん",
    5 => "のんべえさん",
    6 => "太鼓持ちさん",
    7 => "ベテランさん",
    8 => "メガネさん",
    9 => "ツーブロックさん",
    10 => "同期さん",
    11 => "パイセンさん",
    12 => "仕事ざっくりさん",
    13 => "おっさん",
    14 => "感謝でいっぱいさん",
    15 => "伊達男さん",
    16 => "タレントさん",
    17 => "とと姉さん",
    18 => "新潟コシヒカリ魚沼さん",
    19 => "クロワッさん"
  }

  class Forbidden < StandardError ; end
  class NotFound < StandardError ; end

  if Rails.env.production?
    rescue_from Exception , with: :rescue_500
    rescue_from ActionController::RoutingError , with: :rescue_404
    rescue_from ActiveRecord::RecordNotFound , with: :rescue_404
    rescue_from ActionController::ParameterMissing , with: :rescue_400
  end

  rescue_from Forbidden , with: :rescue_403
  rescue_from NotFound , with: :rescue_404

  def init_url
    #@slack_webhooks = "https://hooks.slack.com/services/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"
    @protocol = "http://"
    if Rails.env.production?
      @prizy_url = "http://prizy.me"
      @s3_url = "https://s3-ap-northeast-1.amazonaws.com/prizy"
      @s3_bucket = "prizy"

      sub_domain = request.subdomain
      if sub_domain == "www"
        @protocol = "https://"
        @prizy_url = "https://www.prizy.me"
      end
      # @prizy_url = @protocol + "www.prizy.me"
      @prizy_url = "https://www.prizy.me"
    elsif Rails.env.development?
      @prizy_url = "http://localhost:3000"
      @s3_url = "https://s3-ap-northeast-1.amazonaws.com/btoa-img"
      @s3_bucket = "btoa-img"
    end
  end

  def validate_user
    if @current_user.present?
      unless @current_user.admin == 1
        redirect_page("users", "index")
      end
    end
  end

  def current_user
    user_id = session[:id] || cookies[:id]
    if user_id 
      @current_user||= User.find(user_id)
    end
    if @current_user
      @current_user
    else
      OpenStruct.new(name: "Guest")
    end
  end

  def belonging_team
    # user_id asc
    # {user1 => team1, user2 => team2, user3 => team3}
    @belonging_team = Hash.new
    teams = Team.of_company(@current_user.company_id).available
    users = User.of_company(@current_user.company_id).available
    users.each do |user|
      teams.each do |team|
        @belonging_team.store(user.id, team) if team.member_ids.present? && team.member_ids.split(",").include?(user.id.to_s)
      end
    end
    return @belonging_team
  end

  def logout
    session[:id] = nil
    session[:email] = nil
    cookies.delete :id
    cookies.delete :email
    reset_session

    redirect_to '/login'
  end

  def restrict_access_by_smartphone
    user_agent = request.env["HTTP_USER_AGENT"]
    if(user_agent.include?('Mobile') || user_agent.include?('Android'))
      redirect_to  :controller => "users" , :action  => :index
    end
  end

  def redirect_page(controller, action)
    redirect_to :protocol => @protocol, :controller => controller, :action => action
  end
protected 
  def authenticate_user
    user_id = session[:id] || cookies[:id]
    if user_id
      @current_user = User.find(user_id)
      return true
    else
      redirect_page("users", "login")
      return false
    end
  end

  def save_login_state
    if session[:id] || cookies[:id]
      redirect_page("users", "index")
      return false
    else
      return true
    end
  end
  
  def rescue_400(exception)
    render "errors/bad_request" , status: 400 , layout: "application"
  end

  def rescue_403(exception)
    render "errors/forbidden" , status: 403 , layout: "application"
  end

  def rescue_404(exception)
    render "errors/not_found" , status: 404 , layout: "application"
  end
  def rescue_500(exception)
    render "errors/internal_server_error" , status: 500 , layout: "application"
  end
end
