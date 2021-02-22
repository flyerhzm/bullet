# frozen_string_literal: true

module Bullet
  module ActiveJob
    def self.included(base)
      base.class_eval doaround_perform do |_job, block| Bullet.profile { block.call }endend
    end
  end
end
