module Bullet
  class ActionController
    def self.enable
      case ::Rails::VERSION::STRING
      when /^2.3/
        ::ActionController::Dispatcher.class_eval do
          class <<self
            alias_method :origin_reload_application, :reload_application
            def reload_application
              origin_reload_application
              Bullet.clear
            end
          end
        end
      when /^2.[2|1]/
        ::ActionController::Dispatcher.class_eval do
          alias_method :origin_reload_application, :reload_application
          def reload_application
            origin_reload_application
            Bullet.clear
          end
        end
        
        ::ActionController::Base.class_eval do
          alias_method :origin_process, :process
          def process(request, response, method = :perform_action, *arguments)
            Bullet.start_request
            response = origin_process(request, response, method = :perform_action, *arguments)
            
            if Bullet.notification?
              if response.headers["type"] and response.headers["type"].include? 'text/html' and response.body =~ %r{<html.*</html>}m
                response.body <<= Bullet.javascript_notification
                response.headers["Content-Length"] = response.body.length.to_s
              end
            
              Bullet.growl_notification
              Bullet.log_notification(request.params['PATH_INFO'])
            end
            Bullet.end_request
            response
          end
        end
      else
        puts "Gem Bullet: Unsupported rails version"
      end
    end
  end
end
