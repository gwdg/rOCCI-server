module Backends
  module Now
    #
    # NOW component API
    #
    class NowApi
      include HTTParty

      def initialize(user, options)
        @http_options = { base_uri: options.endpoint, query: { user: user } }
        @options = options
      end

      def get(id)
        result = check('200') do
          self.class.get("/network/#{id}", @http_options)
        end

        JSON(result)
      end

      def list
        result = check('200') do
          result = self.class.get('/network', @http_options)
        end

        JSON(result)
      end

      def create(network)
        @http_options[:body] = network.to_json
        result = check('201') do
          result = self.class.post('/network', @http_options)
        end

        result.to_s
      end

      def delete(id)
        result = check('200') do
          result = self.class.delete("/network/#{id}", @http_options)
        end

        true
      end

      private

      def check(code)
        begin
          result = yield
        rescue Errno::ECONNREFUSED, Errno::ENETUNREACH, SocketError => e
          raise ::Backends::Errors::ServiceUnavailableError, e.message
        end

        unless result.response.code == code
          raise ::Backends::Errors::GenericRESTError.new(result.response.code), result.response.body.to_s
        end

        result
      end
    end
  end
end
