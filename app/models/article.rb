class Article < ActiveRecord::Base
  is_impressionable

	belongs_to :categories
	has_many :titles
	has_many :texts
	has_many :links
	has_many :quotations
	has_many :article_tags
  has_many :tags, through: :article_tags
  has_many :article_likes
  has_many :users, through: :article_likes
  has_many :images
end
