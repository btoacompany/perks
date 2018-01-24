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
    @users = User.of_company(@company.id).available.where(id: member_ids)
              .paginate(page: params[:page], per_page: 20)
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private
  def sidebar 
    @deps = Department.of_company(@company.id).available
  end
end
