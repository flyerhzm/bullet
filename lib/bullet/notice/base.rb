module Bullet
  module Notice
    class Base
      attr_accessor :presenter

      def initialize( console_title, response, call_stack_messages, log_messages )
        @response = response
        @log_messages = log_messages || []
      end

      def has_contents?
        response != nil 
      end

      def title
      end

      def response
        @response.join( "\n" )
      end

      def log_messages
        @log_messages.collect { |msg| msg.join( "\n" ) }
      end

      def present_inline
        return unless self.presenter.respond_to? :present_inline
        self.presenter.send( :inline, self ) 
      end

      def present_out_of_channel
        return unless self.presenter.respond_to? :present_out_of_channel
        self.presenter.send( :out_of_channel, self )
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
