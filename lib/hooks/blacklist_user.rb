module Hooks
  class BlacklistUser

    def initialize(app, options)
      @app = app
      @options = options
    end

    def call(env)
      @app.call(env)
    end

  end
end