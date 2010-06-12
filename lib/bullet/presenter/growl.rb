module Bullet
  module Presenter
    module Growl
      def present( notice )
        growl = Growl.new( 'localhost', 'ruby-growl', [ 'Bullet Notification' ], nil, Bullet.growl_password )

        growl.notify( 'Bullet Notification', 'Bullet Notification', notice.response )
      end
    end 
  end
end
