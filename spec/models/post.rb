class Post < ActiveRecord::Base
  belongs_to :category
  belongs_to :writer
  has_many :comments

  scope :preload_comments, lambda { includes(:comments) }
  scope :in_category_name, lambda { |name|
    where(['categories.name = ?', name]).includes(:category)
  }
end
