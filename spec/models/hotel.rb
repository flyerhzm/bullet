class Hotel < ActiveRecord::Base
  belongs_to :location
  has_many :deals
end
