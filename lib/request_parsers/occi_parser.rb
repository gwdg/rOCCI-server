module RequestParsers
  class OcciParser

    def initialize(app)
      @app = app
    end
    
    def call(env)
      # do nothing, yet
      @app.call(env)
    end

  end
end