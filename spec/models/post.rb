class Post < ActiveRecord::Base
  extend Bullet::Dependency

  belongs_to :category
  belongs_to :writer
  has_many :comments

  if active_record2?
    named_scope :preload_comments, lambda { {:include => :comments} }
    named_scope :in_category_name, lambda { |name|
      {:conditions => ['categories.name = ?', name], :include => :category}
    }
  else
    scope :preload_comments, lambda { includes(:comments) }
    scope :in_category_name, lambda { |name|
      where(['categories.name = ?', name]).includes(:category)
    }
  end
end
