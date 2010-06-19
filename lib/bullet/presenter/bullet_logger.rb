module Bullet
  module Presenter
    class BulletLogger < Base
      LOG_FILE = File.join( Rails.root, 'log/bullet.log' )

      @logger_file = nil
      @logger = nil

      def self.setup
        @logger_file = File.open( LOG_FILE, 'a+' )
        @logger = Bullet::BulletLogger.new( @logger_file )
      end

      def self.active? 
        Bullet.bullet_logger
      end

      def self.out_of_channel( notice )
        return unless active?
        @logger.info notice.full_notice
        @logger_file.flush
      end
    end
  end
end
