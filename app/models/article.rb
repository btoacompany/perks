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

  validates :title, length: {maximum: 240}
  validates :description, length: {maximum: 240}
end
