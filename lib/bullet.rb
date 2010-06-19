require 'bulletware'
require 'set'

module Bullet
  if Rails.version =~ /^3.0/
    autoload :ActiveRecord, 'bullet/active_record3'
  else
    autoload :ActiveRecord, 'bullet/active_record2'
    autoload :ActionController, 'bullet/action_controller2'
  end
  autoload :BulletLogger, 'bullet/logger'
  autoload :Notification, 'bullet/notification'
  autoload :Presenter, 'bullet/presenter'
  autoload :Detector, 'bullet/detector'

  class <<self
    attr_accessor :enable, :alert, :console, :growl, :growl_password, :rails_logger, :bullet_logger, :logger, :logger_file, :disable_browser_cache

    def enable=(enable)
      @enable = enable
      if enable? 
        Bullet::ActiveRecord.enable
        if Rails.version =~ /^3.0/
          require 'action_controller/metal'
          ::ActionController::Metal.middleware_stack.use Bulletware
        elsif Rails.version =~/^2.3/
          Bullet::ActionController.enable
          require 'action_controller/dispatcher'
          ::ActionController::Dispatcher.middleware.use Bulletware
        end
      end
    end

    def enable?
      @enable == true
    end

    def growl=(growl)
      Bullet::Presenter::Growl.setup_connection( self.growl_password ) if growl
      @growl = growl
    end

    def bullet_logger=(bullet_logger)
      if @bullet_logger = bullet_logger
        @logger = Bullet::Presenter::BulletLogger.setup
      end
    end

    DETECTORS = [ Bullet::Detector::NPlusOneQuery, 
                  Bullet::Detector::UnusedEagerAssociation,
                  Bullet::Detector::Counter ]

    PRESENTERS = [ Bullet::Presenter::JavascriptAlert,
                   Bullet::Presenter::JavascriptConsole,
                   Bullet::Presenter::Growl,
                   Bullet::Presenter::RailsLogger,
                   Bullet::Presenter::BulletLogger ]

    def start_request
      reset_notifications
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

    def notification?
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      ! @notifications.empty?
    end

    def add_notification( notification )
      @notifications << notification
    end

    def notifications
      @notifications
    end

    def reset_notifications
      @notifications = Set.new
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
        notifications.each do |notification|
          notification.presenter = presenter
          yield notification
        end
      end
    end
  end

end
