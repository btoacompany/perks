class Admin::TeamsController < Admin::Base
  def index
    @deps = Department.of_company(@company.id).available
  end
end
