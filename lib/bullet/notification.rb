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
      return unless Bullet.alert || Bullet.console

      notice = JavascriptNotice.new( console_title, notification_response, call_stack_messages )

      if notice.has_contents?
        str << notice.for_alert   if Bullet.alert
        str << notice.for_console if Bullet.console
      end
      str
    end

    def growl_notification
      if Bullet.growl
        response = notification_response
        unless response.blank?
          begin
            notice = GrowlNotice.new( nil, response, nil )
            notice.for_growl
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
  end
end
