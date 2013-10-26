require 'action_dispatch/http/request'

module RequestParsers
  class OcciParser

    def initialize(app)
      @app = app
    end
    
    def call(env)
      if collection = parse_occi_messages(env)
        env["rocci_server.request.collection"] = collection
      end

      @app.call(env)
    end

    private

    def parse_occi_messages(env)
      request = ActionDispatch::Request.new(env)

      # TODO: get data from request, body & headers
      # TODO: parse OCCI messages into Occi::Collection
      collection = Occi::Collection.new
      collection.resources << Occi::Infrastructure::Compute.new

      collection
    end

  end
end