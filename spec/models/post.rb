class Post < ActiveRecord::Base
  extend Bullet::Dependency

  belongs_to :category
  belongs_to :writer
  has_many :comments, inverse_of: :post

  scope :preload_comments, -> { includes(:comments) }
  scope :in_category_name, ->(name) { where(['categories.name = ?', name]).includes(:category) }
end
