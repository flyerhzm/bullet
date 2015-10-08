class Mongoid::Company
  include Mongoid::Document

  field :name

  has_one :address, class_name: "Mongoid::Address"
end
