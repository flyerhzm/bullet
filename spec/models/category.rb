class Category < ActiveRecord::Base
  has_many :posts, inverse_of: :category
  has_many :entries

  has_many :submissions
  has_many :users
end
