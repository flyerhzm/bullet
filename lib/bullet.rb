require 'bulletware'

module Bullet
  if Rails.version =~ /^3.0/
    autoload :ActiveRecord, 'bullet/active_record3'
  else
    autoload :ActiveRecord, 'bullet/active_record2'
    autoload :ActionController, 'bullet/action_controller2'
  end
  autoload :Association, 'bullet/association'
  autoload :Counter, 'bullet/counter'
  autoload :BulletLogger, 'bullet/logger'
  autoload :Notification, 'bullet/notification'
  autoload :Presenter, 'bullet/presenter'
  autoload :Notice, 'bullet/notice'

  class <<self
    attr_accessor :enable, :alert, :console, :growl, :growl_password, :rails_logger, :bullet_logger, :logger, :logger_file, :disable_browser_cache

    def enable=(enable)
      @enable = enable
      if enable? 
        Bullet::ActiveRecord.enable
        if Rails.version =~ /^3.0/
          require 'action_controller/metal'
          ::ActionController::Metal.middleware_stack.use Bulletware
        elsif Rails.version =~/^2.3/
          Bullet::ActionController.enable
          require 'action_controller/dispatcher'
          ::ActionController::Dispatcher.middleware.use Bulletware
        end
      end
    end

    def enable?
      @enable == true
    end

    def growl=(growl)
      if growl
        begin
          require 'ruby-growl'
          growl = Growl.new('localhost', 'ruby-growl', ['Bullet Notification'], nil, @growl_password)
          growl.notify('Bullet Notification', 'Bullet Notification', 'Bullet Growl notifications have been turned on')
        rescue MissingSourceFile
          raise NotificationError.new('You must install the ruby-growl gem to use Growl notifications: `sudo gem install ruby-growl`')
        end
      end
      @growl = growl
    end

    def bullet_logger=(bullet_logger)
      if @bullet_logger = bullet_logger
        @logger_file = File.open(Bullet::BulletLogger::LOG_FILE, 'a+')
        @logger = Bullet::BulletLogger.new(@logger_file)
      end
    end

    BULLETS = [Bullet::Association, Bullet::Counter]
    PRESENTERS = [ Bullet::Presenter::JavascriptAlert,
                   Bullet::Presenter::JavascriptConsole,
                   Bullet::Presenter::Growl,
                   Bullet::Presenter::RailsLogger,
                   Bullet::Presenter::BulletLogger ]

    def start_request
      reset_notifications
      BULLETS.each {|bullet| bullet.start_request}
    end

    def end_request
      BULLETS.each {|bullet| bullet.end_request}
    end
    
    def clear
      BULLETS.each {|bullet| bullet.clear}
    end

    def active_presenters
      PRESENTERS.select { |presenter| presenter.send :active? }
    end

    def notification?
      ! @notifications.empty?
    end

    def add_notification( notification )
      @notifications << notification
    end

    def notifications
      @notifications
    end

    def reset_notifications
      @notifications = []
    end
  end

end
