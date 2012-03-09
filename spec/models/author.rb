class Author < ActiveRecord::Base
  has_many :documents
end
