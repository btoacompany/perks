class Admin::DepartmentsController < Admin::Base
  before_action :sidebar, only: [:new, :create, :edit, :update]

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

  def edit
    @department = Department.find(params[:id])
  end

  def update
    @department = Department.find(params[:id])
    if @department.update_attribute(:dep_name, params[:dep_name])
      redirect_to admin_teams_path, notice: "部署名を変更しました"
    else
      redirect_to edit_admin_department_path(@department.id), errors: @department.errors.full_messages
    end
  end

  def destroy
  end

  def sidebar 
    @departments = Department.of_company(@company.id).available
  end
end
