class ArticleCommentsController < ApplicationController
  def create
    logger.debug("===")
    logger.debug(params)
    logger.debug("----")

    article_comment = ArticleComment.new(
      company_id: current_user.company_id,
      article_id: params[:post_id],
      user_id: current_user.id,
      comment: params[:comment]
    )
    if article_comment.save?
      redirect_to "/company/article/#{article_comment.id}"
    else
      redirect_to "/company/article/#{article_comment.id}"
    end
  end

  def destroy
  end

  def update
  end
end
