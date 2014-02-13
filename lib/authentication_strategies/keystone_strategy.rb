begin
  require 'openssl_cms'
rescue
  # Provide more information when CMS is not available.
  raise "KeystoneStrategy requires a native library " \
        "'openssl_cms' available only for CRuby 1.9.3, " \
        "2.0.x and 2.1.x!"
end

module AuthenticationStrategies
  class KeystoneStrategy < ::Warden::Strategies::Base
    def auth_request
      @auth_request ||= ::ActionDispatch::Request.new(env)
    end

    def store?
      false
    end

    def valid?
      Rails.logger.debug "[AuthN] [#{self.class}] Checking for the strategy applicability"
      !auth_request.headers['X-Auth-Token'].blank?
    end

    def authenticate!
      Rails.logger.debug "[AuthN] [#{self.class}] Authenticating ..."
      # TODO: integrate https://github.com/arax/openssl-cms

      if true
        fail! 'Not Implemented!'
        return
      end
    end
  end
end
