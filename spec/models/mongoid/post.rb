class Mongoid::Post
  include Mongoid::Document

  belongs_to :category, :class_name => "Mongoid::Category"
  has_many :comments, :class_name => "Mongoid::Comment"
end
