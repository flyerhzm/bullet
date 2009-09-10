class Bulletware
  BULLETS = [Bullet::Association, Bullet::Counter]
  
  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless Bullet.enable?

    start_request
    status, headers, response = @app.call(env)
    return [status, headers, response] if response.empty?

    if notification?
      if check_html?(headers, response)
        response_body = response.body << javascript_notification
        headers['Content-Length'] = response_body.length.to_s
      end

      growl_notification
      log_notification(env['PATH_INFO'])
    end
    response_body ||= response.body
    end_request
    [status, headers, response_body]
  end
  
  def check_html?(headers, response)
    !headers['Content-Type'].nil? and headers['Content-Type'].include? 'text/html' and response.body =~ %r{<html.*</html>}m
  end

  def start_request
    BULLETS.each {|bullet| bullet.start_request}
  end

  def end_request
    BULLETS.each {|bullet| bullet.end_request}
  end

  def notification?
    BULLETS.any? {|bullet| bullet.notification?}
  end

  def javascript_notification
    BULLETS.collect {|bullet| bullet.javascript_notification if bullet.notification?}.join("\n")
  end

  def growl_notification
    BULLETS.each {|bullet| bullet.growl_notification if bullet.notification?}
  end

  def log_notification(path)
    BULLETS.each {|bullet| bullet.log_notification(path) if bullet.notification?}
  end
end
