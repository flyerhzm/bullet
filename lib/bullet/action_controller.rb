module Bullet
  class ActionController
    def self.enable
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