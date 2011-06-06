class Post < ActiveRecord::Base
  belongs_to :category
  has_many :comments
  belongs_to :writer, :foreign_key => :user_id

  scope :preload_posts, lambda { includes(:comments) }
end
