module Bullet
  module Notice
    class Base
      attr_accessor :presenter

      def initialize( console_title, response, call_stack_messages, log_messages )
        @console_title = console_title || []
        @response = response
        @call_stack_messages = call_stack_messages || []
        @log_messages = log_messages || []
      end

      def has_contents?
        response != nil 
      end

      def title
        @console_title.join( ', ' )
      end

      def response
        @response.join( "\n" )
      end

      def call_stack
        @call_stack_messages.join( "\n" )
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
    end
  end
end
