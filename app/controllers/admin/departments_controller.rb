class Admin::DepartmentsController < Admin::Base
  def new
    @deps = Department.of_company(@company.id)
  end
end
