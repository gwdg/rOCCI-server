module AuthenticationStrategies
  class BasicStrategy < ::Warden::Strategies::Base
    def auth_request
      @auth_request ||= Rack::Auth::Basic::Request.new(env)
    end

    # @see AuthenticationStrategies::DummyStrategy
    def store?
      false
    end

    # @see AuthenticationStrategies::DummyStrategy
    def valid?
      Rails.logger.debug "[AuthN] [#{self.class}] Checking for applicability"
      result = auth_request.provided? && auth_request.basic?

      Rails.logger.debug "[AuthN] [#{self.class}] Strategy is #{result ? '' : 'not '}applicable!"
      result
    end

    # @see AuthenticationStrategies::DummyStrategy
    def authenticate!
      Rails.logger.debug "[AuthN] [#{self.class}] Authenticating ..."

      unless valid_username_provided?(auth_request.username)
        fail! 'Provided username contains invalid characters!'
        return
      end

      user = Hashie::Mash.new
      user.auth!.type = 'basic'
      user.auth!.credentials!.username = auth_request.username
      user.auth!.credentials!.password = auth_request.credentials.last
      user.identity = auth_request.username

      Rails.logger.debug "[AuthN] [#{self.class}] Authenticated #{user.to_hash.inspect}"
      success! user.deep_freeze
    end

    def valid_username_provided?(username)
      /^[[:print:]]+$/.match(username) && /^\S+$/.match(username)
    end
  end
end
