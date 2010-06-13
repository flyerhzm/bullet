module Bullet
  module Presenter
    class JavascriptAlert < Base
      def self.active?
        Bullet.alert
      end

      def self.inline( notice )
        return '' unless active?

        JavascriptHelpers::wrap_js_association "alert( #{notice.full_notice.inspect} ); "
      end
    end
  end
end
