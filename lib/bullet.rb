module Bullet
  @@enable = nil

  class <<self
    def enable=(enable)
      if enable != @@enable && @@enable = enable
        Bullet::ActiveRecord.enable
        # ActiveRecord.send :include, Bullet::ActiveRecord
      end
      @@enable
    end

    def enable?
      class_variables.include?('@@enable') and @@enable == true
    end
  end

  autoload :ActiveRecord, 'bullet/active_record'
  autoload :Association, 'bullet/association'
  autoload :BulletLogger, 'bullet/logger'
end
