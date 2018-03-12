# frozen_string_literal: true

class Client < ActiveRecord::Base
  has_many :relationships
  has_many :firms, through: :relationships
end
