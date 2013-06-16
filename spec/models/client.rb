class Client < ActiveRecord::Base
  has_many :relationships
  has_many :firms, through: :relationships
end
