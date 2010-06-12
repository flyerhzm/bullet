module Bullet
  module Presenter
    class Growl < Base
      def self.active? 
        Base.growl
      end

      def self.out_of_channel( notice )
        return unless active?
        notify( notice.response )
      end

      private
      def self.growl
        Growl.new( 'localhost', 'ruby-growl', [ 'Bullet Notification' ], nil, Bullet.growl_password )
      end

      def self.notify( message )
        growl.notify( 'Bullet Notification', 'Bullet Notification', message )
      end
    end 
  end
end
