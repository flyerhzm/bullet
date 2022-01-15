# frozen_string_literal: true

class Role < ActiveRecord::Base
  has_and_belongs_to_many :users

  belongs_to :resource, polymorphic: true
end
