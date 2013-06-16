class PostsUser < ActiveRecord::Base
  belongs_to :post
  belongs_to :reader, polymorphic: :posts_users
end
