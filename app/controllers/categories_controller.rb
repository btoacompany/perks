class CategoriesController < ApplicationController
  before_action :init

  def init
    if session[:email].present? || cookies[:email].present?
      email = session[:email] || cookies[:email]
      user = User.find_by_email(email)
      unless user.nil?
        if user.admin == 1
          @id = user.company_id
          @user_id = user.id
        end
      else
        redirect_to "/logout"
      end
      @company = Company.find(@id)
    else
      logout
    end
  end

  def index
  	@categories = Category.where(company_id: @company.id, is_deleted: 0)
  end

  def create
    @category = Category.create(
      company_id: @company.id,
      name: params[:name]
      )
    redirect_to company_categories_path
  end

  def update
    @category = Category.find_by(id: params[:id], company_id: @company.id, is_deleted: 0)
    if @category
      @category.update_attribute(:name, params[:name])
    end
    redirect_to company_categories_path
  end

  def destory
  	@category = Category.find_by(id: params[:id], is_deleted: 0, company_id: @company.id)
  	if @category
  		@category.is_deleted = 1
  		@category.save
  	end
  	redirect_to company_categories_path
  end
end
