class Bulletware
  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless Bullet.enable?

    Bullet::Association.start_request
    status, headers, response = @app.call(env)
    return [status, headers, response] if response.empty?

    if Bullet::Association.has_bad_assocations?
      if check_html?(headers, response)
        response_body = response.body << Bullet::Association.javascript_notification
        headers['Content-Length'] = response_body.length.to_s
      end

      Bullet::Association.growl_notification
      Bullet::Association.log_notificatioin(env['PATH_INFO'])
    end
    response_body ||= response.body
    Bullet::Association.end_request
    [status, headers, response_body]
  end
  
  def check_html?(headers, response)
    !headers['Content-Type'].nil? and headers['Content-Type'].include? 'text/html' and response.body =~ %r{<html.*</html>}m
  end
end
