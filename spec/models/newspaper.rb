class Newspaper < ActiveRecord::Base
  has_many :writers
end
