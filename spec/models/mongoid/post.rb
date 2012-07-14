class Mongoid::Post
  include Mongoid::Document

  has_many :comments, :class_name => "Mongoid::Comment"
  belongs_to :category, :class_name => "Mongoid::Category"

  embeds_many :users, :class_name => "Mongoid::User"

  scope :preload_comments, lambda { includes(:comments) }
end
