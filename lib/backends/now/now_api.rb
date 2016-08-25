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
        s = self.class.get("/network/#{id}", @http_options)
        network = JSON(s)

        network
      end

      def list
        s = self.class.get('/network', @http_options)
        networks = JSON(s)

        networks
      end
    end
  end
end
