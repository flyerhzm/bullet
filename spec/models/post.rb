class Post < ActiveRecord::Base
  belongs_to :category
  has_many :comments
  belongs_to :writer


  scope :preload_posts, lambda { includes(:comments) }
  scope :in_category_name, lambda { |name|
    where(['categories.name = ?', name]).includes(:category)
  }
end
