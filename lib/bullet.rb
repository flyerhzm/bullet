module Bullet
  class <<self
    def enable=(enable)
      @@enable = enable
    end

    def enable?
      !@@enable.nil? and @@enable == true
    end
  end

  autoload :Association, 'bullet/association'
  autoload :BulletLogger, 'bullet/logger'
end
