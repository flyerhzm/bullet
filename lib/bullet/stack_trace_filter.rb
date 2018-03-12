# frozen_string_literal: true

module Bullet
  module StackTraceFilter
    VENDOR_PATH = '/vendor'.freeze

    def caller_in_project
      app_root = rails? ? Rails.root.to_s : Dir.pwd
      vendor_root = app_root + VENDOR_PATH
      bundler_path = Bundler.bundle_path.to_s
      select_caller_locations do |caller_path|
        caller_path.include?(app_root) && !caller_path.include?(vendor_root) && !caller_path.include?(bundler_path) ||
          Bullet.stacktrace_includes.any? do |include_pattern|
            case include_pattern
            when String
              caller_path.include?(include_pattern)
            when Regexp
              caller_path =~ include_pattern
            end
          end
      end
    end

    def excluded_stacktrace_path?
      Bullet.stacktrace_excludes.any? do |exclude_pattern|
        caller_in_project.any? do |location|
          caller_path = location.absolute_path.to_s
          case exclude_pattern
          when String
            caller_path.include?(exclude_pattern)
          when Regexp
            caller_path =~ exclude_pattern
          end
        end
      end
    end

    private

    def select_caller_locations
      if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.0.0')
        caller.select do |caller_path|
          yield caller_path
        end
      else
        caller_locations.select do |location|
          caller_path = location.absolute_path.to_s
          yield caller_path
        end
      end
    end
  end
end
