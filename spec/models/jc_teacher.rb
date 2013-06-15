class JcTeacher < ActiveRecord::Base
  has_many :jc_posts_users
  has_many :jc_posts, through: :jc_posts_users
end
