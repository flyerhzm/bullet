class Mongoid::Post
  include Mongoid::Document

  has_many :comments, :class_name => "Mongoid::Comment"
end
