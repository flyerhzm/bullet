# frozen_string_literal: true

class User < ActiveRecord::Base
  has_one :submission
  has_one :submission_attachment, through: :submission, source: :attachment, class_name: 'Attachment'
  belongs_to :category
  has_and_belongs_to_many :roles
end
