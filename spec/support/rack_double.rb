module Support
  class AppDouble
    def call env
      env = @env
      [ status, headers, response ]
    end

    def status= status
      @status = status
    end

    def headers= headers
      @headers = headers
    end

    def headers
      @headers ||= {'Content-Type' => 'text/html'}
      @headers
    end

    def response= response
      @response = response
    end

    private
    def status
      @status || 200
    end

    def response
      @response || ResponseDouble.new
    end
  end

  class ResponseDouble
    def initialize actual_body = nil
      @actual_body = actual_body
    end

    def body
      @body ||= '<html><head></head><body></body></html>'
    end

    def body= body
      @body = body
    end

    def each
      yield body
    end

    def close
    end
  end
end
