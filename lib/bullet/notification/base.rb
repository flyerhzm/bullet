module Bullet
  module Notification
    class Base
      attr_accessor :notifier, :url
      attr_reader :base_class, :associations, :path

      def initialize(base_class, association_or_associations, path = nil)
        @base_class = base_class
        @associations = association_or_associations.is_a?(Array) ?  association_or_associations : [association_or_associations]
        @path = path
      end

      def title
        raise NoMethodError.new("no method title defined")
      end

      def body
        raise NoMethodError.new("no method body defined")
      end

      def whoami
        user = `whoami`
        if user
          "user: #{user.chomp}"
        else
          ""
        end
      end

      def body_with_caller
        body
      end

      def standard_notice
        @standard_notifice ||= title + "\n" + body
      end

      def full_notice
        [whoami, url, title, body_with_caller].compact.join("\n")
      end

      def notify_inline
        self.notifier.inline_notify(self.full_notice)
      end

      def notify_out_of_channel
        self.notifier.out_of_channel_notify(self.full_notice)
      end

      def eql?(other)
        klazz_associations_str == other.klazz_associations_str
      end

      def hash
        klazz_associations_str.hash
      end

      protected
        def klazz_associations_str
          "  #{@base_class} => [#{@associations.map(&:inspect).join(', ')}]"
        end

        def associations_str
          ":include => #{@associations.map{ |a| a.to_s.to_sym unless a.is_a? Hash }.inspect}"
        end
    end
  end
end
