module Bullet
  class ActionController
    def self.enable
      require 'action_controller'
      case Rails.version
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
            response = origin_process(request, response, method, *arguments)
            
            if Bullet.notification?
              if response.headers["type"] and response.headers["type"].include? 'text/html' and response.body =~ %r{<html.*</html>}m
                response.body <<= perform_bullet_inline_notifications
                response.headers["Content-Length"] = response.body.length.to_s
              end
            
              perform_bullet_out_of_channel_notifications
            end
            Bullet.end_request
            response
          end

          def perform_bullet_inline_notifications
            responses = []
            Bullet.active_presenters.each do |presenter|
              Bullet.notifications.collect do |notification|
                notification.presenter = presenter
                responses << notification.present_inline
              end
            end
            responses.join( "\n" )
          end

          def perform_bullet_out_of_channel_notifications
            Bullet.active_presenters.each do |presenter|
              Bullet.notifications.collect do |notification|
                notification.presenter = presenter
                notification.present_out_of_channel
              end
            end
          end
        end
      else
        puts "Gem Bullet: Unsupported rails version"
      end
    end
  end
end
