require 'set'

module Bullet
  class NotificationError < StandardError; end

  if Rails.version =~ /^3.0/
    autoload :ActiveRecord, 'bullet/active_record3'
  else
    autoload :ActiveRecord, 'bullet/active_record2'
    autoload :ActionController, 'bullet/action_controller2'
  end
  autoload :Rack, 'bullet/rack'
  autoload :BulletLogger, 'bullet/logger'
  autoload :Notification, 'bullet/notification'
  autoload :Presenter, 'bullet/presenter'
  autoload :Detector, 'bullet/detector'
  autoload :Registry, 'bullet/registry'
  autoload :NotificationCollector, 'bullet/notification_collector'
  
  if defined? Rails::Railtie
    # compatible with rails 3.0.0.beta4
    class BulletRailtie < Rails::Railtie
      initializer "bullet.configure_rails_initialization" do |app|
        app.middleware.use Bullet::Rack
      end
    end
  end

  class <<self
    attr_accessor :enable, :alert, :console, :growl, :growl_password, :rails_logger, :bullet_logger, :disable_browser_cache, :xmpp
    attr_reader :notification_collector
    
    DETECTORS = [ Bullet::Detector::NPlusOneQuery, 
                  Bullet::Detector::UnusedEagerAssociation,
                  Bullet::Detector::Counter ]

    PRESENTERS = [ Bullet::Presenter::JavascriptAlert,
                   Bullet::Presenter::JavascriptConsole,
                   Bullet::Presenter::Growl,
                   Bullet::Presenter::Xmpp,
                   Bullet::Presenter::RailsLogger,
                   Bullet::Presenter::BulletLogger ]
                   
    def enable=(enable)
      @enable = enable
      if enable? 
        Bullet::ActiveRecord.enable
        if Rails.version =~ /^2./
          Bullet::ActionController.enable
        end
      end
    end

    def enable?
      @enable == true
    end

    def growl=(growl)
      Bullet::Presenter::Growl.setup_connection( self.growl_password ) if growl
    end

    def xmpp=(xmpp)
      Bullet::Presenter::Xmpp.setup_connection( xmpp ) if xmpp
    end

    def bullet_logger=(bullet_logger)
      Bullet::Presenter::BulletLogger.setup if bullet_logger
    end

    def start_request
      notification_collector.reset
      DETECTORS.each {|bullet| bullet.start_request}
    end

    def end_request
      DETECTORS.each {|bullet| bullet.end_request}
    end
    
    def clear
      DETECTORS.each {|bullet| bullet.clear}
    end

    def active_presenters
      PRESENTERS.select { |presenter| presenter.send :active? }
    end

    def notification_collector
      @notification_collector ||= Bullet::NotificationCollector.new
    end

    def notification?
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      notification_collector.notifications_present?
    end

    def gather_inline_notifications
      responses = []
      for_each_active_presenter_with_notification do |notification|
        responses << notification.present_inline
      end
      responses.join( "\n" )
    end

    def perform_out_of_channel_notifications
      for_each_active_presenter_with_notification do |notification|
        notification.present_out_of_channel
      end
    end

    private
      def for_each_active_presenter_with_notification
        active_presenters.each do |presenter|
          notification_collector.collection.each do |notification|
            notification.presenter = presenter
            yield notification
          end
        end
      end
  end

end
