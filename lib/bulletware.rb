class Bulletware
  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless Bullet.enable?

    Bullet.start_request
    status, headers, response = @app.call(env)
    return [status, headers, response] if response.empty?

    if Bullet.notification?
      if check_html?(headers, response)
        response_body = response.body << Bullet.javascript_notification
        headers['Content-Length'] = response_body.length.to_s
      end

      Bullet.growl_notification
      Bullet.log_notification(env['PATH_INFO'])
    end
    response_body ||= response.body
    Bullet.end_request
    [status, headers, response_body]
  end
  
  def check_html?(headers, response)
    !headers['Content-Type'].nil? and headers['Content-Type'].include? 'text/html' and response.body =~ %r{<html.*</html>}m
  end
end
