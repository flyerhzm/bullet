class User < ActiveRecord::Base
  has_many :comments
  has_many :pets
  has_many :documents
end
