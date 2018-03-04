class Article < ActiveRecord::Base
  is_impressionable

	belongs_to :category
	has_many :titles
	has_many :texts
	has_many :links
	has_many :quotations
	has_many :tags
  has_many :users, through: :tags
  has_many :article_likes
  has_many :users, through: :article_likes
  has_many :images

  validates :title, length: {maximum: 250}
  validates :description, length: {maximum: 250}

  scope :available, -> { where(is_deleted: 0) }
  scope :of_company, ->(company_id) { where(company_id: company_id) }
end
