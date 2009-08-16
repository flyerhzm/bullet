module Bullet
  class <<self
    def enable=(enable)
      @@enable = enable
    end

    def enable?
      @@enable == true
    end
  end

  autoload :Association, 'bullet/association'
  autoload :BulletLogger, 'bullet/logger'
end
