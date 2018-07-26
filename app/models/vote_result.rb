class VoteResult < ActiveRecord::Base
  belongs_to :user
  belongs_to :company
  belongs_to :vote

  scope :of_company, ->(company_id) { where(company_id: company_id) }
end
