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
        return unless active?
        notify( notice.full_notice )
      end

      def self.setup_connection( xmpp_information )
        require 'xmpp4r'

        @receiver = xmpp_information[:receiver]
        @password = xmpp_information[:password]
        @account  = xmpp_information[:account]
        @show_online_status = xmpp_information[:show_online_status]

        connect
      rescue MissingSourceFile
        @xmpp = nil
        raise NotificationError.new( 'You must install the xmpp4r gem to use XMPP notifications: `sudo gem install xmpp4r`' )
      end

      private
      def self.connect
        jid = Jabber::JID.new( @account )
        @xmpp = Jabber::Client.new( jid )
        @xmpp.connect
        @xmpp.auth( @password )
        @xmpp.send( presence_status ) if @show_online_status
      end

      def self.notify( message )
        message = Jabber::Message.new( @receiver, message ).
                                  set_type( :normal ).
                                  set_id( '1' ).
                                  set_subject( 'Bullet Notification' )
        @xmpp.send( message )
      end

      def self.presence_status
        project_name = Rails.root.basename.to_s.camelcase
        time = Time.now

        Jabber::Presence.new.set_status( "Bullet in project '#{project_name}' started on #{time}" )
      end
    end
  end
end
