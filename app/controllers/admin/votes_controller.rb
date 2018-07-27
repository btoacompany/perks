class Admin::VotesController < Admin::Base
  before_action :set_record, only: [:show, :edit, :update, :destroy]

  def index
    @votes = Vote.of_company(@user.company_id).date_order(:asc).scheduled
  end
  
  def new
    @vote = Vote.new
  end

  def create
    vote = Vote.new(vote_params)
    vote.company_id = @user.company_id
    if vote.save

      logger.debug("----")
      send_votes
      logger.debug("----")

      redirect_to admin_votes_path, notice: "投票の作成に成功しました"
    else
      redirect_to new_admin_vote_path, notice: "#{vote.errors.full_messages[0]}"
    end
  end

  def show
  end

  def edit
  end

  def update
    if @vote.update_attributes(vote_params)
      redirect_to admin_votes_path, notice: "投票の更新に成功しました"
    else
      redirect_to new_admin_vote_path, notice: "#{vote.errors.full_messages[0]}"
    end
  end

  def destroy
    if @vote.destroy
      redirect_to admin_votes_path, notice: "当該の投票を削除いたしました"
    else
      redirect_to admin_votes_path, notice: "#{vote.errors.full_messages[0]}"
    end
  end

  def send_votes
    # votes = Vote.finished.where(is_delivered: false)
    votes = Vote.where(is_delivered: false)
    votes.each do |vote|
      users = User.of_company(vote.company_id).where(id: [1..20]).available
      @ref_users = users.index_by(&:id)
      voters_info = get_voters_info(vote, users, @ref_users)
      voters_info.each do |info|
        data = {
          vote: vote,
          ref_users: @ref_users,
          email: ENV["SENDGRID_ENABLED"] ? user.email : "naoto.udagawa1230@gmail.com",
          info: info
        }
        # CompanyMailer.vote_mail(data).deliver_now
      end
    end
  end

  private
  def vote_params
    params.permit(:date, :header_image_url, :title, :question)
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

  def get_voters_info(vote, users, ref_users)
    voters_info = users.each_with_object({}) do | user, hash|
      hash.store(user, {team_id: nil, department: nil, candidate_ids: Array.new })
    end
    teams = Team.available.of_company(vote.company_id)
    dep_member_ids = Department.of_company(vote.company_id).available.each_with_object({}) do |dep, hash|
      array = dep.teams.each_with_object([]) do |team, array|
        team.member_ids.split(",").map { |member_id| array << member_id }
      end
      hash.store(dep.id, array.uniq)
    end
    teams.each do |team|
      if team.member_ids.present?
        team.member_ids.split(",").each do |member_id|
          voters_info[ref_users[member_id.to_i]][:team_id] = team.id
          voters_info[ref_users[member_id.to_i]][:department] = team.department
          candidate_ids = team.member_ids.split(",") - [member_id]
          if candidate_ids.count > 2
            voters_info[ref_users[member_id.to_i]][:candidate_ids] = candidate_ids.sample(3)
          else
            voters_info[ref_users[member_id.to_i]][:candidate_ids] = (dep_member_ids[team.department.id] -  [member_id]).sample(3)
          end
        end
      end
    end
    return voters_info
  end
end
