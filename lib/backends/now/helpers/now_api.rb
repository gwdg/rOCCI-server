module Backends
  module Now
    module Helpers
      #
      # NOW component API
      #
      class NowApi
        include HTTParty

        HTTP_OK = '200'.freeze
        HTTP_CREATED = '201'.freeze

        def initialize(user, options)
          @http_options = { base_uri: options.endpoint, query: { user: user } }
          @options = options
        end

        def get(id)
          result = check(HTTP_OK) do
            self.class.get("/network/#{id}", @http_options)
          end

          JSON(result)
        end

        def list
          result = check(HTTP_OK) do
            result = self.class.get('/network', @http_options)
          end

          JSON(result)
        end

        def create(network)
          network.delete 'id'
          @http_options[:body] = network.to_json
          result = check(HTTP_CREATED) do
            result = self.class.post('/network', @http_options)
          end

          result.to_s
        end

        def delete(id)
          result = check(HTTP_OK) do
            result = self.class.delete("/network/#{id}", @http_options)
          end

          true
        end

        def update(id, network)
          network.delete 'id'
          @http_options[:body] = network.to_json
          result = check(HTTP_OK) do
            result = self.class.put("/network/#{id}", @http_options)
          end

          result.to_s
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
end
