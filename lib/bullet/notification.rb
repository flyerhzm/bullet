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
      notice = Notice.new( console_title, notification_response, call_stack_messages )

      if notice.has_contents?
        notice.presenter = Bullet::Notice::Presenter::JavascriptAlert
        str << notice.present_inline
        notice.presenter = Bullet::Notice::Presenter::JavascriptConsole
        str << notice.present_inline
      end
      str
    end

    def growl_notification
      notice = Notice.new( nil, notification_response, nil )
      if notice.has_contents?
        notice.presenter = Bullet::Notice::Presenter::Growl
        notice.present_out_of_channel
      end
    rescue
    end

    def log_notification(path)
      notice = Notice.new( nil, nil, nil, log_messages( path ) )
      notice.presenter = Bullet::Notice::Presenter::RailsLogger
      notice.present_out_of_channel
      
      notice.presenter = Bullet::Notice::Presenter::BulletLogger
      notice.present_out_of_channel
    end
  end
end
