module Bullet
  module Presenter
    module JavascriptConsole
      def present( notice )
        code = <<-CODE
          if (typeof(console) !== 'undefined') {
            if (console.groupCollapsed && console.groupEnd && console.log) {
              console.groupCollapsed(#{notice.title.inspect});
              console.log(#{notice.response.inspect});
              console.log(#{notice.call_stack.inspect});
              console.groupEnd();

            } else if (console.log) {
              console.log(#{notice.response.inspect});
            }
          }
        CODE

        JavascriptHelpers::wrap_js_association code
      end
    end
  end
end
