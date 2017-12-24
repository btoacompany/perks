#coding:utf-8

class Team < ActiveRecord::Base
  self.table_name = "teams"

  before_create :set_create_time
  before_update :set_update_time
  belongs_to :department

  def save_record(params)
    self.department_id	= params[:department_id].to_i if params[:department_id].present?
    self.team_name	= params[:team_name] if params[:team_name].present?
    self.company_id	= params[:company_id] if params[:company_id].present?
    if params[:manager_id].present?
      self.manager_id	= params[:manager_id].to_i 
    else
      self.manager_id = 0
    end
    self.member_ids	= params[:member_ids] if params[:member_ids].present?
    self.save
  end

  def self.teams(company_id)
    team_members = Array.new
    teams = Team.where(company_id: company_id, delete_flag: 0)
    teams.each do |team|
      if team.member_ids.present?
        team_info = { team_id: team.id, members: team.member_ids.split(','), department_id: team.department_id }
        team_members.push(team_info)
      end
    end
    return team_members
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
end
