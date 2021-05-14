# frozen_string_literal: true

module Bullet
  module StackTraceFilter
    VENDOR_PATH = '/vendor'
    IS_RUBY_19 = Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.0.0')

    def caller_in_project
      vendor_root = Bullet.app_root + VENDOR_PATH
      bundler_path = Bundler.bundle_path.to_s
      select_caller_locations do |location|
        location.include?(Bullet.app_root) && !location.include?(vendor_root) &&
          !location.include?(bundler_path) || Bullet.stacktrace_includes.any? { |include_pattern|
          pattern_matches?(location, include_pattern)
        }
      end
    end

    def excluded_stacktrace_path?
      Bullet.stacktrace_excludes.any? do |exclude_pattern|
        caller_in_project.any? { |location| pattern_matches?(location, exclude_pattern) }
      end
    end

    private

    def pattern_matches?(location, pattern)
      path = location_as_path(location)
      case pattern
      when Array
        pattern_path = pattern.first
        filter = pattern.last
        return false unless pattern_matches?(location, pattern_path)

        case filter
        when Range
          filter.include?(location.lineno)
        when Integer
          filter == location.lineno
        when String
          filter == location.base_label
        end
      when String
        path.include?(pattern)
      when Regexp
        path =~ pattern
      end
    end

    def select_caller_locations(&blk)
      callback = Bullet.stacktrace_filter || blk
      if IS_RUBY_19
        caller.select { |caller_path| callback.call caller_path }
      else
        caller_locations.select { |location| callback.call location.absolute_path.to_s }
      end
    end
  end
end
