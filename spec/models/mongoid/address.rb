class Mongoid::Address
  include Mongoid::Document

  belongs_to :company, :class_name => "Mongoid::Company"
end
