class Admin::VotesController < Admin::Base
  before_action :set_record, only: [:show, :edit, :update, :destroy]

  def index
    @votes = Vote.of_company(@user.company_id).order(date: :asc)
  end
  
  def new
    @vote = Vote.new
  end

  def create
    vote = Vote.new(vote_params)
    vote.company_id = @user.company_id
    if vote.save
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
      redirect_to admin_votes_path, notice: "#{vote.errors.full_messages}"
    end
  end

  def demo
  end

  def voted
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
end
