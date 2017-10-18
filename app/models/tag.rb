class Tag < ActiveRecord::Base
	belongs_to :company
	has_many :article_tags
  has_many :articles, through: :article_tags
end
