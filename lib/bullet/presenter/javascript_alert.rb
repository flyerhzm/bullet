module Bullet
  module Presenter
    class JavascriptAlert < Base
      def self.active?
        Bullet.alert
      end

      def self.inline( notice )
        return '' unless self.active?

        JavascriptHelpers::wrap_js_association "alert( #{notice.standard_notice.inspect} ); "
      end
    end
  end
end
