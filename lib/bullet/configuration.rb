module Bullet
  class Configuration
    class <<self
      @@alert = nil
      @@bullet_logger = nil
      @@console = nil
      @@growl = nil
      @@growl_password = nil
      @@rails_logger = nil
      
      def alert=(alert)
        @@alert = alert
      end

      def console=(console)
        @@console = console
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
        @@growl = growl
      end

      def growl_password=(growl_password)
        @@growl_password = growl_password
      end

      def bullet_logger=(bullet_logger)
        if @@bullet_logger = bullet_logger
          @@logger_file = File.open(Bullet::BulletLogger::LOG_FILE, 'a+')
          @@logger = Bullet::BulletLogger.new(@@logger_file)
        end
      end

      def rails_logger=(rails_logger)
        @@rails_logger = rails_logger
      end
    end
  end
end
