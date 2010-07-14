module Bullet
  module Presenter
    class Growl < Base
      @growl = nil

      def self.active? 
        @growl
      end

      def self.out_of_channel( notice )
        return unless active?
        notify( notice.full_notice )
      end

      def self.setup_connection( password )
        require 'ruby-growl'
        @password = password
        @growl = connect

        notify 'Bullet Growl notifications have been turned on'
      rescue MissingSourceFile
        @growl = nil
        raise NotificationError.new( 'You must install the ruby-growl gem to use Growl notifications: `sudo gem install ruby-growl`' )
      end

      private
      def self.connect
        ::Growl.new 'localhost', 
                    'ruby-growl', 
                    [ 'Bullet Notification' ], 
                    nil, 
                    @password 
      end

      def self.notify( message )
        @growl.notify( 'Bullet Notification', 'Bullet Notification', message )
      end
    end 
  end
end
