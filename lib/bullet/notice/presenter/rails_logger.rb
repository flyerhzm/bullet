module Bullet
  module Notice
    module Presenter
      module RailsLogger
        def present( notice )
          Rails.logger.warn ''
          notice.log_messages.each { |msg| Rails.logger.warn msg }
        end
      end
    end
  end
end
