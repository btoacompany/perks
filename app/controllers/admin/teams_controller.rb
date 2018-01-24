class Admin::TeamsController < Admin::Base
  def index
    @deps = Department.of_company(@company.id).available
  end

  def new
  end

  def create
  end

  def show
  end

  def edit
  end

  def update
  end

  def destroy
  end
end
