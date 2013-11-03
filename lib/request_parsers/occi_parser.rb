require 'action_dispatch/http/request'

module RequestParsers
  class OcciParser

    AVAILABLE_PARSERS = {
      'application/occi+json' => ::RequestParsers::Occi::JSON,
      'application/json' => ::RequestParsers::Occi::JSON,
      'text/occi' => ::RequestParsers::Occi::Text,
      'plain/text' => ::RequestParsers::Occi::Text,
      'application/occi+xml' => ::RequestParsers::Occi::XML,
      'application/xml' => ::RequestParsers::Occi::XML
    }.freeze

    def initialize(app)
      @app = app
    end
    
    def call(env)
      request = ::ActionDispatch::Request.new(env)

      begin
        env["rocci_server.request.collection"] = parse_occi_messages(request)
      rescue ::Errors::UnsupportedMediaTypeError => merr
        Rails.logger.warn "Request from #{request.remote_ip} refused with: #{merr.message}"
        return [406, {}, ["Not Acceptable > Unsupported Content Type"]]
      rescue ::Occi::Errors::ParserInputError => perr
        Rails.logger.warn "Request from #{request.remote_ip} refused with: #{perr.message}"
        return [400, {}, ["Bad Request > Malformed Message"]]
      end

      @app.call(env)
    end

    private

    def parse_occi_messages(request)
      raise ::Errors::UnsupportedMediaTypeError, "Media type '#{request.media_type}' is not supported by the RequestParser" unless AVAILABLE_PARSERS.key?(request.media_type)

      body = request.body.respond_to?(:read) ? request.body.read : request.body.string
      collection = AVAILABLE_PARSERS[request.media_type].parse(request.media_type, body, request.headers, request.fullpath)

      collection
    end

  end
end