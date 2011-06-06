class Writer < User
  has_many :posts
  belongs_to :newspaper
end
