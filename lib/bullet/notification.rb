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
      return str unless Bullet.alert || Bullet.console

      notice = Notice::Base.new( console_title, notification_response, call_stack_messages )

      if notice.has_contents?
        if Bullet.alert
          notice.presenter = Bullet::Notice::Presenter::JavascriptAlert
          str << notice.present
        end
        if Bullet.console
          notice.presenter = Bullet::Notice::Presenter::JavascriptConsole
          str << notice.present
        end
      end
      str
    end

    def growl_notification
      return unless Bullet.growl
      notice = Notice::Base.new( nil, notification_response, nil )
      if notice.has_contents?
        notice.presenter = Bullet::Notice::Presenter::Growl
        notice.present
      end
    rescue
    end

    def log_notification(path)
      return unless Bullet.bullet_logger || Bullet.rails_logger

      notice = Notice::Base.new( nil, nil, nil, log_messages( path ) )
      if Bullet.rails_logger
        notice.presenter = Bullet::Notice::Presenter::RailsLogger
        notice.present
      end
      
      if Bullet.bullet_logger
        notice.presenter = Bullet::Notice::Presenter::BulletLogger
        notice.present
      end
    end
  end
end
