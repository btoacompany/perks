class PostsController < ApplicationController
  before_filter :init_url, :authenticate_user
  before_action :init

  def init
    if session[:id].present? || cookies[:id].present?
      @id = session[:id] || cookies[:id]
      user = User.find(@id)
      @user_id = user.id
      @company = Company.find(user.company_id)
    else
      logout
    end
  end

  def update
    post = Post.of_company(@company.id).available.find(params[:post_id])
    if post
      post.update_attributes(description: params[:description])
    end
    redirect_to request.referer
  end
end
