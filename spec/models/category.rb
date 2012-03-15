class Category < ActiveRecord::Base
  has_many :posts
  has_many :entries

  has_many :submissions
  has_many :users
end
