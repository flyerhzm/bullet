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

      def caller_list
        raise NoMethodError.new("no method caller_list defined")
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
        {
          whoami: whoami, 
          url: url, 
          title: title, 
          body: body, #_with_caller
          calllist: caller_list,
        }
      end

      def notify_inline
        self.notifier.inline_notify(self.full_notice.values.compact.join("\n"))
      end

      def notify_out_of_channel
        msg = self.full_notice
        stem = "\n= ".bullet_color('red') + ' '
        outer= "\n========================================".bullet_color('red')

        strOut =  outer + "\tbullet".bullet_color('gray')
        strOut += stem + msg[:title].bullet_color('yellow') + stem
        strOut += stem + '  ' + msg[:url]
        strOut += stem + msg[:body].split("\n").join(stem) unless msg[:body].blank?
        strOut += stem + stem + msg[:calllist].split("\n").uniq!.join(stem) unless msg[:calllist].blank?
        strOut += stem + stem + msg[:whoami]
        strOut += outer + "\n\n"

        self.notifier.out_of_channel_notify(strOut)
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
