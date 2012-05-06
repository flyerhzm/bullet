class Mongoid::Company
  include Mongoid::Document

  has_one :address, :class_name => "Mongoid::Address"
end
