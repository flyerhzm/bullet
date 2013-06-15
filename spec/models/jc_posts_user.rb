class JcPostsUser < ActiveRecord::Base
  belongs_to :jc_post
  belongs_to :reader, polymorphic: :true
end
