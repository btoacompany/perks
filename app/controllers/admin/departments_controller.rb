class Admin::DepartmentsController < Admin::Base
  before_action :sidebar, only: [:new, :create]

  def new
    @department = Department.new
  end

  def create
    @department = Department.new(
      dep_name: params[:dep_name],
      company_id: @company.id
      )
    if @department.save
      redirect_to admin_teams_path, notice: "部署を作成しました"
    else
      render :new, errors: @department.errors.full_messages
    end
  end

  def sidebar 
    @departments = Department.of_company(@company.id).available
  end
end
