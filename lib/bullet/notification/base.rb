module Bullet
  module Notification
    class Base
      attr_accessor :presenter
      attr_reader :base_class, :associations, :path

      def initialize( base_class, associations, path = nil )
        @base_class = base_class
        @associations = associations.is_a?( Array ) ? associations : [ associations ]
        @path = path
      end

      def title
      end

      def body
      end

      def full_notice
        @full_notice ||= title + "\n" + body 
      end

      def present_inline
        return unless self.presenter.respond_to? :inline
        self.presenter.send( :inline, self ) 
      end

      def present_out_of_channel
        return unless self.presenter.respond_to? :out_of_channel
        self.presenter.send( :out_of_channel, self )
      end

      def eql?( other )
        full_notice == other.full_notice
      end

      def hash
        full_notice.hash
      end

      protected
      def klazz_associations_str
        "  #{@base_class} => [#{@associations.map(&:inspect).join(', ')}]"
      end

      def associations_str
        ":include => #{@associations.map{|a| a.to_sym unless a.is_a? Hash}.inspect}"
      end
    end
  end
end
