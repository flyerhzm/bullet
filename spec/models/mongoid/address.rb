class Mongoid::Address
  include Mongoid::Document

  field :name

  belongs_to :company, class_name: "Mongoid::Company"
end
