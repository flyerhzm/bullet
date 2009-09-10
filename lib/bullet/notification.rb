module Bullet
  class NotificationError < StandardError
  end

  module Notification
    def javascript_notification
      str = ''
      if Bullet::Configuration.alert || Bullet::Configuration.console
        response = notification_response
      end
      if Bullet::Configuration.alert
        str << wrap_js_association("alert(#{response.join("\n").inspect});")
      end
      if Bullet::Configuration.console
        code = <<-CODE
          if (typeof(console) !== 'undefined') {

            if (console.groupCollapsed && console.groupEnd && console.log) {

              console.groupCollapsed(#{console_title.join(', ').inspect});
              console.log(#{response.join("\n").inspect});
              console.log(#{call_stack_messages.join("\n").inspect});
              console.groupEnd();

            } else if (console.log) {

              console.log(#{response.join("\n").inspect});
            }
          }
        CODE
        str << wrap_js_association(code)
      end
      str
    end

    def growl_notification
      if Bullet::Configuration.growl
        response = notification_response
        begin
          growl = Growl.new('localhost', 'ruby-growl', ['Bullet Notification'], nil, Bullet::Configuration.growl_password)
          growl.notify('Bullet Notification', 'Bullet Notification', response.join("\n"))
        rescue
        end
      end
    end

    def log_notificatioin(path)
      if Bullet::Configuration.bullet_logger || Bullet::Configuration.rails_logger
        Rails.logger.warn '' if Bullet::Configuration.rails_logger
        messages = log_messages(path)
        messages.each do |message|
          Bullet::Configuration.logger.info(message.join("\n")) if Bullet::Configuration.bullet_logger
          Rails.logger.warn(message.join("\n")) if Bullet::Configuration.rails_logger
        end
        Bullet::Configuration.logger_file.flush if Bullet::Configuration.bullet_logger
      end
    end

    private
      def wrap_js_association(message)
        str = ''
        str << "<script type=\"text/javascript\">/*<![CDATA[*/"
        str << message
        str << "/*]]>*/</script>\n"
      end
  end
end
