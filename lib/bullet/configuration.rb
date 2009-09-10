module Bullet
  class Configuration
    class <<self
      attr_accessor :alert, :bullet_logger, :console, :growl, :growl_password, :rails_logger

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
  end
end
