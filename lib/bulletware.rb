class Bulletware
  def initialize(app)
    @app = app
  end

  def call(env)
    Bullet::Association.start_request
    status, headers, response = @app.call(env)
    if Bullet::Association.has_unpreload_associations?
      if headers['Content-Type'].include? 'text/html'
        inserted_value = "<script type='text/javascript'>"
        inserted_value << "alert('The request has N+1 queries as follows:\\n#{Bullet::Association.unpreload_associations_str}')"
        inserted_value << "</script>\n"
        response_body = response.body[0..-17] + inserted_value + response.body[-16..-1]
        headers['Content-Length'] = response_body.length.to_s
      end
    else
      response_body = response.body
    end
    Bullet::Association.end_request
    [status, headers, response_body]
  end
end
