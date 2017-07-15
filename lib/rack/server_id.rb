require 'rack'

module Rack
  class ServerId
    SPACE = ' '.freeze
    HEADER_KEY = 'Server'.freeze
    SERVER_ID = 'rOCCI-server'.freeze
    COMPLIANT_VERSIONS = %w[OCCI/1.1 OCCI-CRTP/1.0 OCCI/1.2 OCCI-CRTP/1.1].freeze
    CHEEKY_HEADERS = {
      'X-Clacks-Overhead' => 'GNU Terry Pratchett',
      'X-Powered-By' => 'A Sense of Purpose ... and Goblins'
    }.freeze
    SECURITY_HEADERS = {
      'X-Content-Type-Options' => 'nosniff',
      'X-Frame-Options' => 'deny',
      'Content-Security-Policy' => 'default-src \'none\''
    }.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      response = @app.call(env)
      response_headers = response[1]

      response_headers[HEADER_KEY] = server_header
      response_headers.merge! CHEEKY_HEADERS
      response_headers.merge! SECURITY_HEADERS

      response
    end

    private

    def server_header
      "#{SERVER_ID} #{COMPLIANT_VERSIONS.join(SPACE)}"
    end
  end
end
