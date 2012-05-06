class Mongoid::Category
  include Mongoid::Document

  has_many :posts, :class_name => "Mongoid::Post"
  has_many :entries, :class_name => "Mongoid::Entry"
end
