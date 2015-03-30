require "active_support/core_ext/module/delegation"
require 'set'
require 'uniform_notifier'
require 'bullet/ext/object'
require 'bullet/ext/string'
require 'bullet/dependency'

module Bullet
  extend Dependency

  autoload :ActiveRecord, "bullet/#{active_record_version}" if active_record?
  autoload :Mongoid, "bullet/#{mongoid_version}" if mongoid?
  autoload :Rack, 'bullet/rack'
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

  class << self
    attr_writer :enable, :n_plus_one_query_enable, :unused_eager_loading_enable, :counter_cache_enable, :stacktrace_includes
    attr_reader :notification_collector, :whitelist
    attr_accessor :add_footer, :orm_pathches_applied

    delegate :alert=, :console=, :growl=, :html_logger=, :json_logger=, :rails_logger=, :xmpp=, :airbrake=, :bugsnag=, :to => UniformNotifier

    def raise=(should_raise)
      UniformNotifier.raise=(should_raise ? Notification::UnoptimizedQueryError : false)
    end

    DETECTORS = [ Bullet::Detector::NPlusOneQuery,
                  Bullet::Detector::UnusedEagerLoading,
                  Bullet::Detector::CounterCache ]

    def enable=(enable)
      @enable = @n_plus_one_query_enable = @unused_eager_loading_enable = @counter_cache_enable = enable
      if enable?
        reset_whitelist
        unless orm_pathches_applied
          self.orm_pathches_applied = true
          Bullet::Mongoid.enable if mongoid?
          Bullet::ActiveRecord.enable if active_record?
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

    def stacktrace_includes
      @stacktrace_includes || []
    end

    def add_whitelist(options)
      @whitelist[options[:type]][options[:class_name].classify] ||= []
      @whitelist[options[:type]][options[:class_name].classify] << options[:association].to_sym
    end

    def get_whitelist_associations(type, class_name)
      Array(@whitelist[type][class_name])
    end

    def reset_whitelist
      @whitelist = {:n_plus_one_query => {}, :unused_eager_loading => {}, :counter_cache => {}}
    end

    def file_output_setup(extension)
      require 'fileutils'
      root_path = "#{rails? ? Rails.root.to_s : Dir.pwd}"
      FileUtils.mkdir_p(root_path + '/log')
      bullet_log_file = File.open("#{root_path}/log/bullet.#{extension}", 'a+')
      bullet_log_file.sync = true
      return bullet_log_file
    end

    def bullet_logger=(active)
      UniformNotifier.customized_logger = file_output_setup('log') if active
    end

    def json_logger=(active)
      UniformNotifier.json_logger = file_output_setup('json') if active
    end

    def html_logger=(active)
      UniformNotifier.html_logger = file_output_setup('html') if active
    end

    def debug(title, message)
      puts "[Bullet][#{title}] #{message}" if ENV['BULLET_DEBUG'] == 'true'
    end

    def start_request
      Thread.current[:bullet_start] = true
      Thread.current[:bullet_notification_collector] = Bullet::NotificationCollector.new

      Thread.current[:bullet_object_associations] = Bullet::Registry::Base.new
      Thread.current[:bullet_call_object_associations] = Bullet::Registry::Base.new
      Thread.current[:bullet_possible_objects] = Bullet::Registry::Object.new
      Thread.current[:bullet_impossible_objects] = Bullet::Registry::Object.new
      Thread.current[:bullet_inversed_objects] = Bullet::Registry::Base.new
      Thread.current[:bullet_eager_loadings] = Bullet::Registry::Association.new

      Thread.current[:bullet_counter_possible_objects] ||= Bullet::Registry::Object.new
      Thread.current[:bullet_counter_impossible_objects] ||= Bullet::Registry::Object.new
    end

    def end_request
      Thread.current[:bullet_start] = nil
      Thread.current[:bullet_notification_collector] = nil

      Thread.current[:bullet_object_associations] = nil
      Thread.current[:bullet_call_object_associations] = nil
      Thread.current[:bullet_possible_objects] = nil
      Thread.current[:bullet_impossible_objects] = nil
      Thread.current[:bullet_inversed_objects] = nil
      Thread.current[:bullet_eager_loadings] = nil

      Thread.current[:bullet_counter_possible_objects] = nil
      Thread.current[:bullet_counter_impossible_objects] = nil
    end

    def start?
      Thread.current[:bullet_start]
    end

    def notification_collector
      Thread.current[:bullet_notification_collector]
    end

    def notification?
      return unless start?
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
        notification.url = env['REQUEST_URI']
        notification.notify_out_of_channel
      end
    end

    def footer_info
      info = []
      for_each_active_notifier_with_notification do |notification|
        info << notification.short_notice
      end
      info
    end

    def warnings
      notification_collector.collection.inject({}) do |warnings, notification|
        warning_type = notification.class.to_s.split(':').last.tableize
        warnings[warning_type] ||= []
        warnings[warning_type] << notification
        warnings
      end
    end

    def profile
      Bullet.start_request if Bullet.enable?

      yield

      if Bullet.enable? && Bullet.notification?
        Bullet.perform_out_of_channel_notifications
      end
      Bullet.end_request if Bullet.enable?
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
