class UserPostedContent < ActiveRecord::Base
  belongs_to :company
  belongs_to :user

  validates :description , presence: true , length: {maximum: 250}
end
