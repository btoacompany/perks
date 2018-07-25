class Vote < ActiveRecord::Base
  validates :date, presence: true
  validates :title, presence: true, length: { maximum: 40 }
  validates :question, presence: true, length: { maximum: 50 }
  validate :not_before_today

  def not_before_today
    errors.add(:date, '明日以降の日付を選択してください') if date.nil? || date <= Date.today
  end
end
