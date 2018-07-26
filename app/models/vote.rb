class Vote < ActiveRecord::Base
  has_many :vote_results

  validates :date, presence: true
  validates :title, presence: true, length: { maximum: 40 }
  validates :question, presence: true, length: { maximum: 50 }
  validate :not_before_today

  scope :of_company, ->(company_id) { where(company_id: company_id) }

  def not_before_today
    errors.add(:date, 'を明日以降で選択してください') if date.nil? || date <= Date.today
  end
end
