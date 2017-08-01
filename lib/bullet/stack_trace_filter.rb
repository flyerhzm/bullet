module Bullet
  module StackTraceFilter
    VENDOR_PATH = '/vendor'.freeze

    def caller_in_project
      app_root = rails? ? Rails.root.to_s : Dir.pwd
      vendor_root = app_root + VENDOR_PATH
      caller_locations.select do |location|
        caller_path = location.absolute_path.to_s
        caller_path.include?(app_root) && !caller_path.include?(vendor_root) ||
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
        caller_in_project.any? do |caller_path|
          case exclude_pattern
          when String
            caller_path.include?(exclude_pattern)
          when Regexp
            caller_path =~ exclude_pattern
          end
        end
      end
    end
  end
end
