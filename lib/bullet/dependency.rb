module Bullet
  module Dependency
    def mongoid?
      @mongoid ||= defined? ::Mongoid
    end

    def active_record?
      @active_record ||= defined? ::ActiveRecord
    end

    def rails?
      @rails ||= defined? ::Rails
    end

    def active_record_version
      @active_record_version ||= begin
                                   if active_record30?
                                     'active_record3'
                                   elsif active_record31? || active_record32?
                                     'active_record3x'
                                   elsif active_record40?
                                     'active_record4'
                                   elsif active_record41?
                                     'active_record41'
                                   elsif active_record42?
                                     'active_record42'
                                   elsif active_record50?
                                     'active_record5'
                                   end
                                 end
    end

    def mongoid_version
      @mongoid_version ||= begin
                             if mongoid2x?
                               'mongoid2x'
                             elsif mongoid3x?
                               'mongoid3x'
                             elsif mongoid4x?
                               'mongoid4x'
                             elsif mongoid5x?
                               'mongoid5x'
                             end
                           end
    end

    def active_record3?
      active_record? && ::ActiveRecord::VERSION::MAJOR == 3
    end

    def active_record4?
      active_record? && ::ActiveRecord::VERSION::MAJOR == 4
    end

    def active_record5?
      active_record? && ::ActiveRecord::VERSION::MAJOR == 5
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

    def active_record40?
      active_record4? && ::ActiveRecord::VERSION::MINOR == 0
    end

    def active_record41?
      active_record4? && ::ActiveRecord::VERSION::MINOR == 1
    end

    def active_record42?
      active_record4? && ::ActiveRecord::VERSION::MINOR == 2
    end

    def active_record50?
      active_record5? && ::ActiveRecord::VERSION::MINOR == 0
    end

    def mongoid2x?
      mongoid? && ::Mongoid::VERSION =~ /\A2\.[4-8]/
    end

    def mongoid3x?
      mongoid? && ::Mongoid::VERSION =~ /\A3/
    end

    def mongoid4x?
      mongoid? && ::Mongoid::VERSION =~ /\A4/
    end

    def mongoid5x?
      mongoid? && ::Mongoid::VERSION =~ /\A5/
    end
  end
end
