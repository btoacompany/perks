class Admin::VoteResultsController < Admin::Base
  before_action :set_record, only: :show

  def index
    @votes = Vote.of_company(@user.company_id).finished.where(is_delivered: true).date_order
    @total_employee_count = User.of_company(@user.company_id).available.count
  end

  def show
    @users = User.of_company(@user.company_id).available.index_by(&:id)
    @departments = Department.of_company(@user.company_id).available
    dep_headcount = get_dep_headcount(@departments)
    dep_resultcount = VoteResult.of_company(@user.company_id).of_vote(params[:id]).group(:department_id).count
    @dep_response_rate = get_response_rate(dep_headcount, dep_resultcount)
    @dep_ranking = Hash[ VoteResult.of_company(@user.company_id).of_department(params[:department_id]).of_vote(params[:id]).group(:result).count.sort_by{ |_, v| -v } ]
    @dep_total_vote = VoteResult.of_company(@user.company_id).of_vote(params[:id]).of_department(params[:department_id]).count
  end

  def post_vote
    if VoteResult.create(vote_result_params)
      redirect_to admin_vote_result_path(vote_result_params[:vote_id]), notice: "投票しました"
    else
      redirect_to admin_votes_path, notice: "投票に失敗しました"
    end
  end

  private
  def get_dep_headcount(departments)
    departments.each_with_object({}) do |dep, hash |
      count = 0
      dep.teams.map { |team| count += team.member_ids.split(",").count }
      hash.store(dep, count )
    end
  end

  def get_response_rate(dep_headcount, dep_resultcount)
    dep_headcount.each_with_object({}) do |(key, value), hash |
      dep_resultcount[key.id].present? ? dep_resultcount[key.id] : dep_resultcount[key.id] = 0
      hash.store(key.dep_name, (dep_resultcount[key.id] / value.to_f).round(3))
    end
  end

  def set_record
    @vote = Vote.find_by(
      id: params[:id],
      company_id: @user.company_id
    )
    unless @vote
      raise ActiveRecord::RecordNotFound, "Vote is not found"
    end
  end

  def vote_result_params
    params.permit(:user_id, :company_id, :team_id, :department_id, :vote_id, :result)
  end
end
