module Bullet
  module Dependency
    def mongoid?
      @mongoid ||= begin
                     require 'mongoid'
                     mongoid_version.present?
                   rescue LoadError
                     false
                   end
    end

    def active_record?
      @active_record ||= begin
                           require 'active_record'
                           true
                         rescue LoadError
                           false
                         end
    end

    def active_record_version
      @active_record_version ||= begin
                                   if active_record30?
                                     'active_record3'
                                   elsif active_record31? || active_record32?
                                     'active_record3x'
                                   elsif active_record4?
                                     'active_record4'
                                   end
                                 end
    end

    def mongoid_version
      @mongoid_version ||= begin
                             if mongoid2x?
                               'mongoid2x'
                             elsif mongoid3x?
                               'mongoid3x'
                             end
                           end
    end

    def active_record3?
      ::ActiveRecord::VERSION::MAJOR == 3
    end

    def active_record4?
      ::ActiveRecord::VERSION::MAJOR == 4
    end

    def active_record30?
      active_record3? && ::ActiveRecord::VERSION::MINOR == 0
    end

    def active_record31?
      active_record3? && ::ActiveRecord::VERSION::MINOR == 1
    end

    def active_record32?
      active_record3? && ::ActiveRecord::VERSION::MINOR == 2
    end

    def mongoid2x?
      ::Mongoid::VERSION =~ /\A2\.[4|5]/
    end

    def mongoid3x?
      ::Mongoid::VERSION =~ /\A3/
    end

    def rails?
      @rails ||= begin
                   require 'rails'
                   true
                 rescue LoadError
                   false
               end
    end
  end
end
