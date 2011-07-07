require 'set'
require 'uniform_notifier'

module Bullet
  if Rails.version =~ /^3.0/
    autoload :ActiveRecord, 'bullet/active_record3'
  else
    autoload :ActiveRecord, 'bullet/active_record2'
    autoload :ActionController, 'bullet/action_controller2'
  end
  autoload :Rack, 'bullet/rack'
  autoload :BulletLogger, 'bullet/logger'
  autoload :Notification, 'bullet/notification'
  autoload :Detector, 'bullet/detector'
  autoload :Registry, 'bullet/registry'
  autoload :NotificationCollector, 'bullet/notification_collector'

  if defined? Rails::Railtie
    class BulletRailtie < Rails::Railtie
      initializer "bullet.configure_rails_initialization" do |app|
        app.middleware.use Bullet::Rack
      end
    end
  end

  class <<self
    attr_accessor :enable, :disable_browser_cache
    attr_reader :notification_collector

    delegate :alert=, :console=, :growl=, :rails_logger=, :xmpp=, :to => UniformNotifier

    DETECTORS = [ Bullet::Detector::NPlusOneQuery,
                  Bullet::Detector::UnusedEagerAssociation,
                  Bullet::Detector::Counter ]

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

    def bullet_logger=(active)
      if active
        bullet_log_file = File.open( 'log/bullet.log', 'a+' )
        bullet_log_file.sync
        UniformNotifier.customized_logger = bullet_log_file
      end
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

    def notification_collector
      @notification_collector ||= Bullet::NotificationCollector.new
    end

    def notification?
      Bullet::Detector::UnusedEagerAssociation.check_unused_preload_associations
      notification_collector.notifications_present?
    end

    def gather_inline_notifications
      responses = []
      for_each_active_notifier_with_notification do |notification|
        responses << notification.notify_inline
      end
      responses.join( "\n" )
    end

    def perform_out_of_channel_notifications(env = {})
      for_each_active_notifier_with_notification do |notification|
        notification.url = [env['HTTP_HOST'], env['REQUEST_URI']].compact.join
        notification.notify_out_of_channel
      end
    end

    private
      def for_each_active_notifier_with_notification
        UniformNotifier.active_notifiers.each do |notifier|
          notification_collector.collection.each do |notification|
            notification.notifier = notifier
            yield notification
          end
        end
      end
  end

end
