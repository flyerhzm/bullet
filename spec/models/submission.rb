# frozen_string_literal: true

class Submission < ActiveRecord::Base
  belongs_to :user
  has_many :replies
  has_one :attachment
end
