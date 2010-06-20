module Bullet
  module Presenter
    class Xmpp < Base
      @receiver = nil
      @xmpp = nil
      @password = nil

      def self.active?
        @xmpp
      end

      def self.out_of_channel( notice )
        Rails.logger.debug "XMPP: out-of-channel #{notice.inspect}"
        return unless active?
        notify( notice.full_notice )
      end

      def self.setup_connection( xmpp_information )
        require 'xmpp4r'

        @receiver = xmpp_information[:receiver]
        @password = xmpp_information[:password]
        @account  = xmpp_information[:account]

        connect
      rescue MissingSourceFile
        @xmpp = nil
        raise NotificationError.new( 'You must install the xmpp4r gem to use XMPP notifications: `sudo gem install xmpp4r`' )
      end

      private
      def self.connect
        Rails.logger.debug "Connecting to xmpp server..."
        jid = Jabber::JID.new( @account )
        @xmpp = Jabber::Client.new( jid )
        @xmpp.connect
        @xmpp.auth( @password )
        Rails.logger.debug "Connected to xmpp server"
      end

      def self.notify( message )
        message = Jabber::Message.new( @receiver, message ).
                                  set_type( :normal ).
                                  set_id( '1' ).
                                  set_subject( 'Bullet Notification' )
        Rails.logger.debug "XMPP: Sending message: #{message.inspect}"
        @xmpp.send( message )
        Rails.logger.debug "XMPP: Message sent."
      end
    end
  end
end
