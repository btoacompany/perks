class Tag < ActiveRecord::Base
	belongs_to :article
	belongs_to :user

  scope :of_company, ->(company_id) { where(company_id: company_id) }
end
