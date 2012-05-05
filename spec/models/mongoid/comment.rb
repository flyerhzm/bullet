class Mongoid::Comment
  include Mongoid::Document

  belongs_to :post, :class_name => "Mongoid::Post"
end
