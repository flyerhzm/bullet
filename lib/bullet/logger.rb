module Bullet
  class BulletLogger < Logger
    LOG_FILE = File.join(Rails.root, 'log/bullet.log')

    def format_message(severity, timestamp, progname, msg)
      "#{timestamp.to_formatted_s(:db)}[#{severity}] #{msg}\n"
    end
  end
end
