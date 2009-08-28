module Bullet
  @@enable = nil

  class <<self
    def enable=(enable)
      @@enable = enable
      if enable? 
        Bullet::ActiveRecord.enable
        ActionController::Dispatcher.middleware.use Bulletware
      end
    end

    def enable?
      @@enable == true
    end
  end

  autoload :ActiveRecord, 'bullet/active_record'
  autoload :Association, 'bullet/association'
  autoload :BulletLogger, 'bullet/logger'
end
