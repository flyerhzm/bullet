# frozen_string_literal: true

module Bullet
  module Dependency
    def mongoid?
      @mongoid ||= defined?(::Mongoid)
    end

    def active_record?
      @active_record ||= defined?(::ActiveRecord)
    end

    def active_record_version
      @active_record_version ||=
        begin
          if active_record6_or_older?
            raise "Bullet no longer supports active_record #{::ActiveRecord::VERSION::STRING}"
          elsif active_record70?
            'active_record70'
          elsif active_record71?
            'active_record71'
          elsif active_record72?
            'active_record72'
          elsif active_record80?
            'active_record80'
          elsif active_record81?
            'active_record81'
          elsif active_record82?
            'active_record82'
          else
            raise "Bullet does not support active_record #{::ActiveRecord::VERSION::STRING} yet"
          end
        end
    end

    def mongoid_version
      @mongoid_version ||=
        begin
          if mongoid4x?
            'mongoid4x'
          elsif mongoid5x?
            'mongoid5x'
          elsif mongoid6x?
            'mongoid6x'
          elsif mongoid7x?
            'mongoid7x'
          elsif mongoid8x?
            'mongoid8x'
          elsif mongoid9x?
            'mongoid9x'
          else
            raise "Bullet does not support mongoid #{::Mongoid::VERSION} yet"
          end
        end
    end

    def active_record6_or_older?
      active_record? && ::ActiveRecord::VERSION::MAJOR < 7
    end

    def active_record7?
      active_record? && ::ActiveRecord::VERSION::MAJOR == 7
    end

    def active_record8?
      active_record? && ::ActiveRecord::VERSION::MAJOR == 8
    end

    def active_record70?
      active_record7? && ::ActiveRecord::VERSION::MINOR == 0
    end

    def active_record71?
      active_record7? && ::ActiveRecord::VERSION::MINOR == 1
    end

    def active_record72?
      active_record7? && ::ActiveRecord::VERSION::MINOR == 2
    end

    def active_record80?
      active_record8? && ::ActiveRecord::VERSION::MINOR == 0
    end

    def active_record81?
      active_record8? && ::ActiveRecord::VERSION::MINOR == 1
    end

    def active_record82?
      active_record8? && ::ActiveRecord::VERSION::MINOR == 2
    end

    def mongoid4x?
      mongoid? && ::Mongoid::VERSION =~ /\A4/
    end

    def mongoid5x?
      mongoid? && ::Mongoid::VERSION =~ /\A5/
    end

    def mongoid6x?
      mongoid? && ::Mongoid::VERSION =~ /\A6/
    end

    def mongoid7x?
      mongoid? && ::Mongoid::VERSION =~ /\A7/
    end

    def mongoid8x?
      mongoid? && ::Mongoid::VERSION =~ /\A8/
    end

    def mongoid9x?
      mongoid? && ::Mongoid::VERSION =~ /\A9/
    end
  end
end
