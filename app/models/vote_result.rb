class VoteResult < ActiveRecord::Base
  belongs_to :user
  belongs_to :company
  belongs_to :department
  belongs_to :team
  belongs_to :vote

  scope :of_company, ->(company_id) { where(company_id: company_id) }
  scope :of_department, ->(department_id) { where(department_id: department_id) }
  scope :of_vote, ->(vote_id) { where(vote_id: vote_id) }

  validates :vote_id, uniqueness: { scope: :user_id }
end
