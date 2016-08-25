module Backends
  module Now

    class NowApi
      include HTTParty

      def initialize(user, options)
        @http_options = { base_uri: options.endpoint, query: {user: user} }
        @options = options
      end

      def get(id)
        s = self.class.get("/network/#{id}", @http_options)
        network = JSON(s)
      end

      def list
        s = self.class.get("/network", @http_options)
        networks = JSON(s)
      end

    end

  end
end
