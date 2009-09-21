module Bullet
  class NotificationError < StandardError
  end

  module Notification
    def notification?
    end

    def notification_response
    end

    def console_title
    end

    def log_message(path = nil)
    end

    def javascript_notification
      str = ''
      if Bullet.alert || Bullet.console
        response = notification_response
      end
      unless response.blank?
        if Bullet.alert
          str << wrap_js_association("alert(#{response.join("\n").inspect});")
        end
        if Bullet.console
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
      end
      str
    end

    def growl_notification
      if Bullet.growl
        response = notification_response
        unless response.blank?
          begin
            growl = Growl.new('localhost', 'ruby-growl', ['Bullet Notification'], nil, Bullet.growl_password)
            growl.notify('Bullet Notification', 'Bullet Notification', response.join("\n"))
          rescue
          end
        end
      end
    end

    def log_notification(path)
      if Bullet.bullet_logger || Bullet.rails_logger
        Rails.logger.warn '' if Bullet.rails_logger
        messages = log_messages(path)
        messages.each do |message|
          Bullet.logger.info(message.join("\n")) if Bullet.bullet_logger
          Rails.logger.warn(message.join("\n")) if Bullet.rails_logger
        end
        Bullet.logger_file.flush if Bullet.bullet_logger
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
