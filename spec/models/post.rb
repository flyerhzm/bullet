class Post < ActiveRecord::Base
  extend Bullet::Dependency

  belongs_to :category
  belongs_to :writer
  has_many :comments, :inverse_of => :post

  scope :preload_comments, lambda { includes(:comments) }
  scope :in_category_name, lambda { |name|
    where(['categories.name = ?', name]).includes(:category)
  }
end
