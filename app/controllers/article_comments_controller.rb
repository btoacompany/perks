class ArticleCommentsController < ApplicationController
  def create
    article_comment = ArticleComment.new(
      company_id: current_user.company_id,
      article_id: params[:post_id].to_i,
      user_id: current_user.id,
      comment: params[:comments].gsub(/\n/, '<br>'),
      is_nickname: params[:is_nickname],
      create_time: Time.now,
      update_time: Time.now
    )
    if article_comment.save
      redirect_to :back, notice: "コメントを送信いたしました"
    else
      redirect_to :back, notice: "#{article_comment.errors.full_messages}"
    end
  end

  def destroy
    article_comment = ArticleComment.find(params[:id])
    article_comment.delete
    redirect_to :back, notice: "コメントを削除しました"
  end

  def update
  end
end
