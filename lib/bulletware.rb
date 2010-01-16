class Bulletware
  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless Bullet.enable?

    Bullet.start_request
    status, headers, response = @app.call(env)
    return [status, headers, response] if empty?(response)

    if Bullet.notification?
      if status == 200 and !response.body.frozen? and check_html?(headers, response)
        response_body = response.body << Bullet.javascript_notification
        headers['Content-Length'] = response_body.length.to_s
      end

      Bullet.growl_notification
      Bullet.log_notification(env['PATH_INFO'])
    end
    response_body ||= response.body
    Bullet.end_request
    no_browser_cache(headers) if Bullet.disable_browser_cache
    [status, headers, response_body]
  end

  # fix issue if response's body is a Proc
  def empty?(response)
    (response.is_a?(Array) && response.empty?) || !response.body.is_a?(String) || response.body.empty?
  end
  
  def check_html?(headers, response)
    headers['Content-Type'] and headers['Content-Type'].include? 'text/html' and response.body =~ %r{<html.*</html>}m
  end

  def no_browser_cache(headers)
    headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    headers["Pragma"] = "no-cache"
    headers["Expires"] = "Wed, 09 Sep 2009 09:09:09 GMT"
  end
end
