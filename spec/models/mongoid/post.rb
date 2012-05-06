class Mongoid::Post
  include Mongoid::Document

  has_many :comments, :class_name => "Mongoid::Comment"
  belongs_to :category, :class_name => "Mongoid::Category"

  scope :preload_comments, lambda { includes(:comments) }
end
