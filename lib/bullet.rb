require 'bulletware'

module Bullet
  class <<self
    attr_accessor :enable, :alert, :console, :growl, :growl_password, :rails_logger, :bullet_logger, :logger, :logger_file

    def enable=(enable)
      @enable = enable
      if enable? 
        Bullet::ActiveRecord.enable
        ActionController::Dispatcher.middleware.use Bulletware
      end
    end

    def enable?
      @enable == true
    end

    def growl=(growl)
      if growl
        begin
          require 'ruby-growl'
          growl = Growl.new('localhost', 'ruby-growl', ['Bullet Notification'], nil, @@growl_password)
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
  end

  autoload :ActiveRecord, 'bullet/active_record'
  autoload :Association, 'bullet/association'
  autoload :Counter, 'bullet/counter'
  autoload :BulletLogger, 'bullet/logger'
  autoload :Notification, 'bullet/notification'
end
