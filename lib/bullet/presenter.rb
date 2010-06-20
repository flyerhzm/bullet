module Bullet
  module Presenter
    autoload :Base, 'bullet/presenter/base'
    autoload :JavascriptAlert, 'bullet/presenter/javascript_alert'
    autoload :JavascriptConsole, 'bullet/presenter/javascript_console'
    autoload :Growl, 'bullet/presenter/growl'
    autoload :Xmpp, 'bullet/presenter/xmpp'
    autoload :BulletLogger, 'bullet/presenter/bullet_logger'
    autoload :RailsLogger, 'bullet/presenter/rails_logger'
  end
end
