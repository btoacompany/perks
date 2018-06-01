class ArticleComment < ActiveRecord::Base
  belongs_to :article
  belongs_to :user

  validates :comment, presence: true, length: {maximum: 2000}

  scope :available, -> { where(is_deleted: false) }
end
