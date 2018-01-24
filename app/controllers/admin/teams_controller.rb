class Admin::TeamsController < Admin::Base
  before_action :sidebar, only: [:index, :new, :show, :edit]

  def index
  end

  def new
  end

  def create
  end

  def show
    @team = Team.find_by(id: params[:id], company_id: @company.id)
    member_ids = []
    @team.member_ids.split(",").map { |id| member_ids.push(id.to_i) } if @team.member_ids.present?
    @members = User.of_company(@company.id).available.where(id: member_ids)
              .paginate(page: params[:page], per_page: 20)
  end

  def edit
    @team = Team.find_by(id: params[:id], company_id: @company.id)
    member_ids = Array.new
    @team.member_ids.split(",").map { |id| member_ids.push(id.to_i) } if @team.member_ids.present?
    @members = User.of_company(@company.id).available.where(id: member_ids)
              .paginate(page: params[:page], per_page: 20)
    @emails = Array.new
    @emails = @members.map { |member| @emails.push(member.email) }
  end



  def update
    @team = Team.find_by(id: params[:team_id], company_id: @company.id)
    # if @team.company_id == @id
    member_ids = []
      # if params[:members].reject(&:blank?).blank?
      #   redirect_to "/company/teams/edit/#{@team.id}", notice: "少なくとも一人以上の社員を登録してください。"
      #   return
      # end
    members = params[:members].delete_if{|n| n.empty? }
    members.each do |mem|
      user = User.find_by(email: mem, delete_flag: 0)
      if user.present?
        member_ids << user.id.to_s
      else
        redirect_to "/company/teams/edit/#{@team.id}", notice: "登録できませんでした。メールアドレスが一致しません。"
        return
      end
    end
    member_ids.uniq!
    params[:member_ids] = member_ids.join(",")
    @team.save_record(params)
    redirect_to admin_team_path(@team.id)
  end

  def destroy
  end

  private
  def sidebar 
    @deps = Department.of_company(@company.id).available
  end
end
