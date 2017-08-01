class Newspaper < ActiveRecord::Base
  has_many :writers, class_name: 'BaseUser'
end
