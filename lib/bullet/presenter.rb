module Bullet
  module Presenter
    autoload :Base, 'bullet/presenter/base'
    autoload :JavascriptAlert, 'bullet/presenter/javascript_alert'
    autoload :JavascriptConsole, 'bullet/presenter/javascript_console'
    autoload :Growl, 'bullet/presenter/growl'
    autoload :BulletLogger, 'bullet/presenter/bullet_logger'
    autoload :RailsLogger, 'bullet/presenter/rails_logger'
  end
end
