module Bullet
  module Dependency
    def mongoid?
      @mongoid ||= begin
                     require 'mongoid'
                     true
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
                                   if active_record2?
                                     'active_record2'
                                   elsif active_record30?
                                     'active_record3'
                                   elsif active_record31? || active_record32?
                                     'active_record31'
                                   end
                                 end
    end

    def mongoid_version
      @mongoid_version ||= begin
                             if mongoid24?
                               'mongoid24'
                             elsif mongoid3?
                               'mongoid3'
                             end
                           end
    end

    def active_record2?
      ::ActiveRecord::VERSION::MAJOR == 2
    end

    def active_record23?
      active_record2? && ::ActiveRecord::VERSION::MINOR == 3
    end

    def active_record22?
      active_record2? && ::ActiveRecord::VERSION::MINOR == 2
    end

    def active_record21?
      active_record2? && ::ActiveRecord::VERSION::MINOR == 1
    end

    def active_record3?
      ::ActiveRecord::VERSION::MAJOR == 3
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

    def mongoid24?
      ::Mongoid::VERSION =~ /\A2\.4/
    end

    def mongoid3?
      ::Mongoid::VERSION =~ /\A3/
    end
  end
end
