class Deal < ActiveRecord::Base
  belongs_to :hotel
  has_one :location, :through => :hotel
end
