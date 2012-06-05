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
  end
end
