require 'set'
require 'uniform_notifier'
require 'bullet/ext/object'
require 'bullet/ext/string'
require 'bullet/dependency'

module Bullet
  extend Dependency

  if active_record?
    autoload :ActiveRecord, "bullet/#{active_record_version}"
    autoload :ActionController, 'bullet/action_controller2' if active_record2?
  end
  if mongoid?
    autoload :Mongoid, "bullet/#{mongoid_version}"
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
    attr_writer :enable, :n_plus_one_query_enable, :unused_eager_loading_enable, :counter_cache_enable
    attr_reader :notification_collector

    delegate :alert=, :console=, :growl=, :rails_logger=, :xmpp=, :airbrake=, :to => UniformNotifier

    DETECTORS = [ Bullet::Detector::NPlusOneQuery,
                  Bullet::Detector::UnusedEagerLoading,
                  Bullet::Detector::CounterCache ]

    def enable=(enable)
      @enable = @n_plus_one_query_enable = @unused_eager_loading_enable = @counter_cache_enable = enable
      if enable?
        if mongoid?
          Bullet::Mongoid.enable
        end
        if active_record?
          Bullet::ActiveRecord.enable
          Bullet::ActionController.enable if active_record2?
        end
      end
    end

    def enable?
      !!@enable
    end

    def n_plus_one_query_enable?
      self.enable? && !!@n_plus_one_query_enable
    end

    def unused_eager_loading_enable?
      self.enable? && !!@unused_eager_loading_enable
    end

    def counter_cache_enable?
      self.enable? && !!@counter_cache_enable
    end

    def bullet_logger=(active)
      if active
        bullet_log_file = File.open("#{rails2? ? RAILS_ROOT : Rails.root.to_s}/log/bullet.log", 'a+')
        bullet_log_file.sync = true
        UniformNotifier.customized_logger = bullet_log_file
      end
    end

    def start_request
      notification_collector.reset
      DETECTORS.each { |bullet| bullet.start_request }
    end

    def end_request
      DETECTORS.each { |bullet| bullet.end_request }
    end

    def clear
      DETECTORS.each { |bullet| bullet.clear }
    end

    def notification_collector
      @notification_collector ||= Bullet::NotificationCollector.new
    end

    def notification?
      Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
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

    def warnings
      notification_collector.collection.inject({}) do |warnings, notification|
        warning_type = notification.class.to_s.split(':').last.tableize
        warnings[warning_type] ||= []
        warnings[warning_type] << notification
        warnings
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
