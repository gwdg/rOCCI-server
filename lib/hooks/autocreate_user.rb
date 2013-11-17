module Hooks
  class AutocreateUser

    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    end

  end
end