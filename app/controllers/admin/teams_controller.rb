class Admin::TeamsController < Admin::Base
  before_action :sidebar, only: [:index, :new, :show, :edit, :update]
  before_action :display_team, only: [:show, :edit, :update]

  def index
  end

  def new
  end

  def create
  end

  def show
  end

  def edit
    @emails = User.of_company(@company.id).available.pluck(:email)
  end

  def update
    @emails = User.of_company(@company.id).available.pluck(:email)
    member_ids = Array.new
    members = params[:members].delete_if{|n| n.empty?}
    members.each do |mem|
      user = User.find_by!(email: mem, delete_flag: 0)
      member_ids << user.id.to_s
    end
    params[:member_ids] = member_ids.uniq.join(",")
    if @team.save_record(params)
      redirect_to admin_team_path(@team.id)
    else
      flash[:notice] = "登録できませんでした。一人以上メンバーを追加して下さい"
      render :edit
    end
    rescue => e
      redirect_to edit_admin_team_path(@team.id), notice: "登録できませんでした。メールアドレスが一致しません。"
      return
  end

  def destroy
  end

  private
  def sidebar 
    @deps = Department.of_company(@company.id).available
  end

  def display_team
    @team = Team.find_by(id: params[:id], company_id: @company.id)
    member_ids = Array.new
    @team.member_ids.split(",").map { |id| member_ids.push(id.to_i) } if @team.member_ids.present?
    @members = User.of_company(@company.id).available.where(id: member_ids)
              .paginate(page: params[:page], per_page: 20)
  end
end
