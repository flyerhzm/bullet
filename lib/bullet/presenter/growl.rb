module Bullet
  module Presenter
    module Growl
      def self.out_of_channel( notice )
        return unless Bullet.growl
        growl = Growl.new( 'localhost', 'ruby-growl', [ 'Bullet Notification' ], nil, Bullet.growl_password )

        growl.notify( 'Bullet Notification', 'Bullet Notification', notice.response )
      end
    end 
  end
end
