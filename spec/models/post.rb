class Post < ActiveRecord::Base
  extend Bullet::Dependency

  belongs_to :category
  belongs_to :writer
  has_many :comments, inverse_of: :post
  has_many :posts_users
  has_many :students, through: :posts_users, source: :reader, source_type: "Student"
  has_many :teachers, through: :posts_users, source: :reader, source_type: "Teacher"

  scope :preload_comments, -> { includes(:comments) }
  scope :in_category_name, ->(name) { where(['categories.name = ?', name]).includes(:category) }
end
