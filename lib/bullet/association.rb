module Bullet
  class BulletAssociationError < StandardError
  end

  class Association
    class <<self
      @@alert = nil
      @@bullet_logger = nil
      @@console = nil
      @@growl = nil
      @@growl_password = nil
      @@rails_logger = nil

      ###################################################
      # Configurations
      ###################################################
      def alert=(alert)
        @@alert = alert
      end

      def console=(console)
        @@console = console
      end

      def growl=(growl)
        if growl
          begin
            require 'ruby-growl'
            growl = Growl.new('localhost', 'ruby-growl', ['Bullet Notification'], nil, @@growl_password)
            growl.notify('Bullet Notification', 'Bullet Notification', 'Bullet Growl notifications have been turned on')
          rescue MissingSourceFile
            raise BulletAssociationError.new('You must install the ruby-growl gem to use Growl notifications: `sudo gem install ruby-growl`')
          end
        end
        @@growl = growl
      end

      def growl_password=(growl_password)
        @@growl_password = growl_password
      end

      def bullet_logger=(bullet_logger)
        if @@bullet_logger = bullet_logger
          @@logger_file = File.open(Bullet::BulletLogger::LOG_FILE, 'a+')
          @@logger = Bullet::BulletLogger.new(@@logger_file)
        end
      end

      def rails_logger=(rails_logger)
        @@rails_logger = rails_logger
      end

      #####################################################
      # login control interface
      #####################################################
      def start_request
        # puts "start request"
      end

      def end_request
        # puts "end request"
        @@object_associations = nil
        @@unpreload_associations = nil
        @@unused_preload_associations = nil
        @@callers = nil
        @@possible_objects = nil
        @@impossible_objects = nil
        @@call_object_associations = nil
        @@eager_loadings = nil
      end

      def has_bad_assocations?
        check_unused_preload_associations
        has_unpreload_associations? or has_unused_preload_associations?
      end

      ######################################################
      # Notifications
      ######################################################
      def javascript_notification
        str = ''
        if @@alert || @@console
          response = notification_response
        end
        if @@alert
          str << wrap_js_association("alert(#{response.join("\n").inspect});")
        end
        if @@console
          title = []
          title << unused_preload_messages.first.first unless unused_preload_messages.empty?
          title << unpreload_messages.first.first unless unpreload_messages.empty?
          code = <<-CODE
            if (typeof(console) !== 'undefined') {

              if (console.groupCollapsed && console.groupEnd && console.log) {

                console.groupCollapsed(#{title.join(', ').inspect});
                console.log(#{response.join("\n").inspect});
                console.log(#{call_stack_messages.join("\n").inspect});
                console.groupEnd();

              } else if (console.log) {

                console.log(#{response.join("\n").inspect});
              }
            }
          CODE
          str << wrap_js_association(code)
        end
        str
      end

      def growl_notification
        if @@growl
          response = notification_response
          begin
            growl = Growl.new('localhost', 'ruby-growl', ['Bullet Notification'], nil, @@growl_password)
            growl.notify('Bullet Notification', 'Bullet Notification', response.join("\n"))
          rescue
          end
        end
      end

      def log_notificatioin(path)
        if (@@bullet_logger || @@rails_logger) && (!unpreload_associations.empty? || !unused_preload_associations.empty?)
          Rails.logger.warn '' if @@rails_logger
          unused_preload_messages(path).each do |message|
            @@logger.info(message.join("\n")) if @@bullet_logger
            Rails.logger.warn(message.join("\n")) if @@rails_logger
          end
          unpreload_messages(path).each do |message|
            @@logger.info(message.join("\n")) if @@bullet_logger
            Rails.logger.warn(message.join("\n")) if @@rails_logger
          end
          call_stack_messages.each do |message|
            @@logger.info(message.join("\n")) if @@bullet_logger
            Rails.logger.warn(message.join("\n")) if @@rails_logger
          end
          @@logger_file.flush if @@bullet_logger
        end
      end

      def add_unpreload_associations(klazz, associations)
        # puts "add unpreload associations, #{klazz} => #{associations.inspect}"
        unpreload_associations[klazz] ||= []
        unpreload_associations[klazz] << associations
        unique(unpreload_associations[klazz])
      end

      def add_unused_preload_associations(klazz, associations)
        # puts "add unused preload associations, #{klazz} => #{associations.inspect}"
        unused_preload_associations[klazz] ||= []
        unused_preload_associations[klazz] << associations
        unique(unused_preload_associations[klazz])
      end

      def add_association(object, associations)
        # puts "add associations, #{object} => #{associations.inspect}"
        object_associations[object] ||= []
        object_associations[object] << associations
        unique(object_associations[object])
      end

      ###################################################
      # interface for active record
      ###################################################
      def add_call_object_associations(object, associations)
        # puts "add call object associations, #{object} => #{associations.inspect}"
        call_object_associations[object] ||= []
        call_object_associations[object] << associations
        unique(call_object_associations[object])
      end

      def add_possible_objects(objects)
        # puts "add possible objects, #{objects.inspect}"
        klazz= objects.first.class
        possible_objects[klazz] ||= []
        possible_objects[klazz] << objects
        unique(possible_objects[klazz])
      end

      def add_impossible_object(object)
        # puts "add impossible object, #{object}"
        klazz = object.class
        impossible_objects[klazz] ||= []
        impossible_objects[klazz] << object
        impossible_objects[klazz].uniq!
      end

      def add_klazz_associations(klazz, associations)
        # puts "define associations, #{klazz} => #{associations.inspect}"
        klazz_associations[klazz] ||= []
        klazz_associations[klazz] << associations
        unique(klazz_associations[klazz])
      end

      def add_eager_loadings(objects, associations)
        # puts "add eager loadings, #{objects.inspect} => #{associations.inspect}"
        objects = Array(objects)
        eager_loadings[objects] ||= []
        eager_loadings[objects] << associations
        unique(eager_loadings[objects])
      end

      def define_association(klazz, associations)
        # puts "define association, #{klazz} => #{associations.inspect}"
        add_klazz_associations(klazz, associations)
      end

      def call_association(object, associations)
        # puts "call association, #{object} => #{associations.inspect}"
        add_call_object_associations(object, associations)
        if unpreload_associations?(object, associations)
          add_unpreload_associations(object.class, associations)
          caller_in_project
        end
      end

      ############################################
      # for rspec
      ############################################
      def check_unused_preload_associations
        object_associations.each do |object, association|
          related_objects = eager_loadings.select {|key, value| key.include?(object) and value == association}.collect(&:first).flatten
          call_object_association = related_objects.collect { |related_object| call_object_associations[related_object] }.compact.flatten.uniq
          diff_object_association = (association - call_object_association).reject {|a| a.is_a? Hash}
          add_unused_preload_associations(object.class, diff_object_association) unless diff_object_association.empty?
        end
      end

      def has_unused_preload_associations?
        !unused_preload_associations.empty?
      end

      def has_unpreload_associations?
        !unpreload_associations.empty?
      end


      private
      def unpreload_associations?(object, associations)
        klazz = object.class
        (!possible_objects[klazz].nil? and possible_objects[klazz].include?(object)) and
        (impossible_objects[klazz].nil? or !impossible_objects[klazz].include?(object)) and
        (object_associations[object].nil? or !object_associations[object].include?(associations))
      end

      def notification_response
        response = []
        if has_unused_preload_associations?
          response << unused_preload_messages.join("\n")
        end
        if has_unpreload_associations?
          response << unpreload_messages.join("\n")
        end
        response
      end

      def unused_preload_messages(path = nil)
        messages = []
        unused_preload_associations.each do |klazz, associations|
          messages << [
            "Unused Eager Loading #{path ? "in #{path}" : 'detected'}",
            klazz_associations_str(klazz, associations),
            "  Remove from your finder: #{associations_str(associations)}"
          ]
        end
        messages
      end

      def unpreload_messages(path = nil)
        messages = []
        unpreload_associations.each do |klazz, associations|
          messages << [
            "N+1 Query #{path ? "in #{path}" : 'detected'}",
            klazz_associations_str(klazz, associations),
            "  Add to your finder: #{associations_str(associations)}"
          ]
        end
        messages
      end

      def klazz_associations_str(klazz, associations)
        "  #{klazz} => [#{associations.map(&:inspect).join(', ')}]"
      end

      def associations_str(associations)
        ":include => #{associations.map{|a| a.to_sym unless a.is_a? Hash}.inspect}"
      end

      def wrap_js_association(message)
        str = ''
        str << "<script type=\"text/javascript\">/*<![CDATA[*/"
        str << message
        str << "/*]]>*/</script>\n"
      end

      def call_stack_messages
        callers.inject([]) do |messages, c|
          messages << ['N+1 Query method call stack', c.collect {|line| "  #{line}"}].flatten
        end
      end
      
      def unique(array)
        array.flatten!
        array.uniq!
      end

      def unpreload_associations
        @@unpreload_associations ||= {}
      end

      def unused_preload_associations
        @@unused_preload_associations ||= {}
      end

      def object_associations
        @@object_associations ||= {}
      end

      def call_object_associations
        @@call_object_associations ||= {}
      end

      def possible_objects
        @@possible_objects ||= {}
      end

      def impossible_objects
        @@impossible_objects ||= {}
      end

      def klazz_associations
        @@klazz_associations ||= {}
      end

      def eager_loadings
        @@eager_loadings ||= {}
      end

      VENDOR_ROOT = File.join(RAILS_ROOT, 'vendor')
      def caller_in_project
        callers << caller.select {|c| c =~ /#{RAILS_ROOT}/}.reject {|c| c =~ /#{VENDOR_ROOT}/}
        callers.uniq!
      end

      def callers
        @@callers ||= []
      end
    end
  end
end
