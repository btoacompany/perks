class Vote < ActiveRecord::Base
  validates :date, presence: true
  validates :title, presence: true, length: { maximum: 40 }
  validates :question, presence: true, length: { maximum: 50 }
end
