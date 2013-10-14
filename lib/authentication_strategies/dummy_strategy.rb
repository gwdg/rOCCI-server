module AuthenticationStrategies
  class DummyStrategy < ::Warden::Strategies::Base
    def valid?
      true
    end

    def authenticate!
      user = Hashie::Mash.new
      user.auth!.type = "dummy"
      user.auth!.credentials!.username = "dummy_user"
      user.auth!.credentials!.password = "dummy_password"

      success! user
    end
  end
end