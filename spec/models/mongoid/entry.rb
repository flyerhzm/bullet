class Mongoid::Entry
  include Mongoid::Document

  field :name

  belongs_to :category, class_name: "Mongoid::Category"
end
