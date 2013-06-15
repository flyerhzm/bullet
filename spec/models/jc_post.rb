class JcPost < ActiveRecord::Base
  extend Bullet::Dependency
  has_many :jc_posts_users
  has_many :jc_students, through: :jc_posts_users, source: :reader, source_type: :JcStudent
  has_many :jc_teachers, through: :jc_posts_users, source: :reader, source_type: :JcTeacher
end
