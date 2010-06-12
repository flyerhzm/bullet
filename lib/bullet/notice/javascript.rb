module Bullet
  module Notice
    class Javascript < Base
      def for_alert
        wrap_js_association("alert(#{response.inspect});")
      end

      def for_console
        code = <<-CODE
          if (typeof(console) !== 'undefined') {
            if (console.groupCollapsed && console.groupEnd && console.log) {
              console.groupCollapsed(#{title.inspect});
              console.log(#{response.inspect});
              console.log(#{call_stack.inspect});
              console.groupEnd();

            } else if (console.log) {
              console.log(#{response.inspect});
            }
          }
        CODE
        wrap_js_association(code)
      end

      private
      def wrap_js_association(message)
        str = ''
        str << "<script type=\"text/javascript\">/*<![CDATA[*/"
        str << message
        str << "/*]]>*/</script>\n"
      end
    end
  end
end
