class Admin::VoteResultsController < Admin::Base
  def index
    @votes = Vote.of_company(@user.company_id).order(date: :asc).finished.date_order
    @total_employee_count = User.of_company(@user.company_id).available.count
  end

  def show
  end
end
