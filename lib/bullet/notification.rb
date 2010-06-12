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
      return unless Bullet.growl
      notice = GrowlNotice.new( nil, notification_response, nil )
      notice.for_growl if notice.has_contents?
    rescue
    end

    def log_notification(path)
      return unless Bullet.bullet_logger || Bullet.rails_logger

      notice = LogNotice.new( nil, nil, nil, log_messages( path ) )
      notice.for_rails_log if Bullet.rails_logger
      notice.for_bullet_log if Bullet.bullet_logger
    end
  end
end
