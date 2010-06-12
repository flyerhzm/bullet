module Bullet
  class LogNotice < Notice
    def for_rails_log
      Rails.logger.warn ''
      log_messages.each { |msg| Rails.logger.warn( msg ) }
    end

    def for_bullet_log
      log_messages.each { |msg| Bullet.logger.info( msg ) }
      Bullet.logger_file.flush
    end
  end
end
