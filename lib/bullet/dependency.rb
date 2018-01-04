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
                                   if active_record40?
                                     'active_record4'
                                   elsif active_record41?
                                     'active_record41'
                                   elsif active_record42?
                                     'active_record42'
                                   elsif active_record50?
                                     'active_record5'
                                   elsif active_record51?
                                     'active_record52'
                                   elsif active_record52?
                                     'active_record52'
                                   else
                                     raise "Bullet does not support active_record #{::ActiveRecord::VERSION} yet"
                                   end
                                 end
    end

    def mongoid_version
      @mongoid_version ||= begin
                             if mongoid4x?
                               'mongoid4x'
                             elsif mongoid5x?
                               'mongoid5x'
                             elsif mongoid6x?
                               'mongoid6x'
                             else
                               raise "Bullet does not support mongoid #{::Mongoid::VERSION} yet"
                             end
                           end
    end

    def active_record4?
      active_record? && ::ActiveRecord::VERSION::MAJOR == 4
    end

    def active_record5?
      active_record? && ::ActiveRecord::VERSION::MAJOR == 5
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

    def active_record51?
      active_record5? && ::ActiveRecord::VERSION::MINOR == 1
    end

    def active_record52?
      active_record5? && ::ActiveRecord::VERSION::MINOR == 2
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
  end
end
