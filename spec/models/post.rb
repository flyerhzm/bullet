# frozen_string_literal: true

class Post < ActiveRecord::Base
  belongs_to :category, inverse_of: :posts
  belongs_to :writer
  has_many :comments, inverse_of: :post

  validates :category, presence: true

  scope :preload_comments, -> { includes(:comments) }
  scope :in_category_name, ->(name) { where(['categories.name = ?', name]).includes(:category) }
  scope :draft, -> { where(active: false) }

  def link=(*)
    comments.new
  end
end
