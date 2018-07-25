class Admin::VotesController < Admin::Base
  before_action :set_record, only: [:edit, :destroy]

  def index
    @votes = Vote.of_company(@user.company_id)
  end
  
  def new
  end

  def create
    vote = Vote.new(vote_params)
    vote.company_id = @user.company_id
    if vote.save
      redirect_to admin_votes_path, notice: "投票の作成に成功しました"
    else
      redirect_to new_admin_vote_path, notice: "#{vote.errors.full_messages}"
    end
  end

  def show
  end

  def destroy
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
