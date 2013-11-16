module AuthenticationStrategies
  class DummyStrategy < ::Warden::Strategies::Base

    def valid?
      Rails.logger.debug "[AuthN] [#{self.class}] Checking for the strategy applicability"
      true
    end

    def store?
      false
    end

    def authenticate!
      Rails.logger.debug "[AuthN] [#{self.class}] Authenticating ..."

      user = Hashie::Mash.new
      user.auth!.type = "dummy"
      user.auth!.credentials!.username = "dummy_user"
      user.auth!.credentials!.password = "dummy_password"

      Rails.logger.debug "[AuthN] [#{self.class}] Authenticated #{user.to_hash.inspect}"
      success! user
    end

  end
end