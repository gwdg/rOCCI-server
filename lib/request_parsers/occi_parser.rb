require 'action_dispatch/http/request'

module RequestParsers
  class OcciParser
    AVAILABLE_PARSERS = {
      'application/occi+json' => ::RequestParsers::Occi::JSON,
      'application/json' => ::RequestParsers::Occi::JSON,
      'text/occi' => ::RequestParsers::Occi::Text,
      'text/plain' => ::RequestParsers::Occi::Text,
      #'application/occi+xml' => ::RequestParsers::Occi::XML,
      #'application/xml' => ::RequestParsers::Occi::XML,
      'text/html' => ::RequestParsers::Occi::Dummy,
      '' => ::RequestParsers::Occi::Dummy,
    }.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      request = ::ActionDispatch::Request.new(env)

      # make a copy of the request body
      @body = request.body.respond_to?(:read) ? request.body.read : request.body.string
      @body = Marshal.load(Marshal.dump(@body))

      # save copy some additional information
      @media_type = request.media_type.to_s
      @headers = sanitize_request_headers(request.headers)
      @fullpath = request.fullpath.to_s

      env['rocci_server.request.parser'] = self
      @app.call(env)
    end

    def parse_occi_messages(entity_type = nil)
      fail ::Errors::UnsupportedMediaTypeError, "Media type '#{@media_type}' is not supported by the RequestParser" unless AVAILABLE_PARSERS.key?(@media_type)

      collection = if entity_type
                     AVAILABLE_PARSERS[@media_type].parse(@media_type, @body, @headers, @fullpath, entity_type)
                   else
                     AVAILABLE_PARSERS[@media_type].parse(@media_type, @body, @headers, @fullpath)
                   end
      Rails.logger.debug "[Parser] [#{self.class}] Parsed request into coll=#{collection.inspect}"

      collection
    end

    def sanitize_request_headers(headers)
      headers.select { |_, v| v.kind_of?(String) }
    end
    private :sanitize_request_headers
  end
end
