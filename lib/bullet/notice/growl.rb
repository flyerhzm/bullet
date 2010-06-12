module Bullet
  module Notice
    class Growl < Base
      def for_growl
        growl.notify('Bullet Notification', 'Bullet Notification', response)
      end

      private
      def growl
        Growl.new('localhost', 'ruby-growl', ['Bullet Notification'], nil, Bullet.growl_password)
      end
    end
  end
end
