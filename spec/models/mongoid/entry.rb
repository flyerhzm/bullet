class Mongoid::Entry
  include Mongoid::Document

  belongs_to :category, :class_name => "Mongoid::Category"
end
