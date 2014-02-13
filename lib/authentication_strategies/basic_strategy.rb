module AuthenticationStrategies
  class BasicStrategy < ::Warden::Strategies::Base
    def auth
      @auth ||= Rack::Auth::Basic::Request.new(env)
    end

    def store?
      false
    end

    def valid?
      Rails.logger.debug "[AuthN] [#{self.class}] Checking for the strategy applicability"
      auth.provided? && auth.basic?
    end

    def authenticate!
      Rails.logger.debug "[AuthN] [#{self.class}] Authenticating ..."

      unless valid_username_provided?(auth.username)
        fail!('Provided username contains invalid characters!')
        return
      end

      user = Hashie::Mash.new
      user.auth!.type = 'basic'
      user.auth!.credentials!.username = auth.username
      user.auth!.credentials!.password = auth.credentials.last

      Rails.logger.debug "[AuthN] [#{self.class}] Authenticated #{user.to_hash.inspect}"
      success! user
    end

    def valid_username_provided?(username)
      /^[[:print:]]+$/.match(username) && /^\S+$/.match(username)
    end
  end
end
