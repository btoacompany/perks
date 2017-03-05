#coding:utf-8
require 'csv'

class Department < ActiveRecord::Base
  self.table_name = "departments"

  before_create :set_create_time
  before_update :set_update_time

  def save_record(params)
    self.dep_name	= params[:dep_name]
    self.company_id	= params[:company_id]
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

  def self.create_department_and_team_by_csv(file , current_user)
    logger.debug("OK")
    CSV.foreach(file.path , headers: true) do |row_data|
      logger.debug("OK")
      # create department unless department is not presence
      department = Department.find_by(dep_name: row_data["department"])
      unless department
        department = Department.new
        department.dep_name = row_data["department"]
        department.company_id = current_user.company_id
        department.save!
      end
      # create team unless team is not presence
      team = Team.find_by(department_id: department.id , team_name: row_data["team"])
      unless team
        team = Team.new
        team.department_id = department.id
        team.company_id = current_user.company_id
        team.manager_id = current_user.id
        team.member_ids = current_user.id.to_i
        team.team_name = row_data["team"]
        logger.debug("#{team.errors.messages}")
        team.save!
      end
    end
  end
end
