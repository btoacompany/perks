class Admin::EmployeesController < Admin::Base
  def edit
    @employee = User.find_by(id: params[:id], company_id: @company.id)
    @departments = Department.where(company_id: @company.id, delete_flag: 0).order(sort: :asc)
    teams = Team.teams(@company.id)
    teams.each do |team|
      if team[:members].include?(@employee.id.to_s)
        @department = Department.find_by(company_id: @company.id, delete_flag: 0, id: team[:department_id])
        @teams = @department.teams if @department
      end
    end
  end

  def update
    ActiveRecord::Base.transaction do
      if params[:id] && params[:team_id]
        @employee = User.find(params[:id])
        teams = Team.where(@company.id)
        next_team = Team.find(params[:team_id])
        if @employee && next_team
          @employee.update_attribute(:lastname, params[:lastname])
          @employee.update_attribute(:firstname, params[:firstname])
          @employee.update_attribute(:email, params[:email])
          @employee.update_attribute(:gender, params[:gender].to_i)

          teams.each do |lastteam|
            if lastteam.member_ids && lastteam.member_ids.include?(',') && lastteam.member_ids.include?(@employee.id.to_s)
              test = [params[:id].to_s]
              lastteam.member_ids = (lastteam.member_ids.split(",") - (test)).join(",")
            elsif lastteam.member_ids && lastteam.member_ids.include?(@employee.id.to_s)
              lastteam.member_ids = lastteam.member_ids.delete(@employee.id.to_s)
            end
            lastteam.save
          end
          next_team = Team.find(params[:team_id])

          if next_team.member_ids.present? && next_team.member_ids.length > 0
            next_team.member_ids = next_team.member_ids + ',' + @employee.id.to_s
          else
            next_team.member_ids = @employee.id.to_s
          end
          if next_team.save && @employee.valid?
            flash[:success] = "社員情報を変更いたしました"
            redirect_to company_employees_path
          else
            flash[:error] = "社員情報の編集に失敗しました"
            edit_admin_employee_path(@employee.id)
          end
        end
      else
        flash[:error] = "チームが選択されていません"
        redirect_to edit_admin_employee_path(params[:id])
      end
    end
    rescue => e
      flash[:error] = "#{e}"
      redirect_to edit_admin_employee_path(@employee.id)
  end
end
