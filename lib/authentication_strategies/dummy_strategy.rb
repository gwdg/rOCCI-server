module AuthenticationStrategies
  class DummyStrategy < ::Warden::Strategies::Base
    def valid?
      Rails.logger.debug "AuthN subsystem: Checking for the applicability of DummyStrategy."
      true
    end

    def authenticate!
      Rails.logger.debug "AuthN subsystem: Authenticating with DummyStrategy."

      user = Hashie::Mash.new
      user.auth!.type = "dummy"
      user.auth!.credentials!.username = "dummy_user"
      user.auth!.credentials!.password = "dummy_password"

      Rails.logger.debug "AuthN subsystem: Authenticated #{user.to_hash.inspect} with DummyStrategy."
      success! user
    end
  end
end