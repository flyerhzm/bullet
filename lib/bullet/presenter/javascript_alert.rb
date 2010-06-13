module Bullet
  module Presenter
    class JavascriptAlert < Base
      def self.active?
        Rails.logger.debug "Active: #{Bullet.alert}"
        Bullet.alert
      end

      def self.inline( notice )
        return '' unless self.active?
        Rails.logger.debug "Alert active!"

        JavascriptHelpers::wrap_js_association "alert( #{notice.full_notice.inspect} ); "
      end
    end
  end
end
