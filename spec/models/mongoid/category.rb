class Mongoid::Category
  include Mongoid::Document

  has_many :posts, :class_name => "Mongoid::Post"
end
