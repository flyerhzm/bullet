module Bullet
  class <<self
    def enable=(enable)
      @@enable = enable
    end

    def enable?
      class_variables.include?('@@enable') and @@enable == true
    end
  end

  autoload :Association, 'bullet/association'
  autoload :BulletLogger, 'bullet/logger'
end
