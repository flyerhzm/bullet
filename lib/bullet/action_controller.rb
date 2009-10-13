module Bullet
  class ActionController
    def self.enable
      if Rails::VERSION::STRING.to_f < 2.3
        ::ActionController::Dispatcher.class_eval do
          alias_method :origin_reload_application, :reload_application
          
          def reload_application
            origin_reload_application
            Bullet.clear
          end
        end
      else
        ::ActionController::Dispatcher.class_eval do
          class <<self
            alias_method :origin_reload_application, :reload_application
            
            def reload_application
              origin_reload_application
              Bullet.clear
            end
          end
        end
      end
    end
  end
end
