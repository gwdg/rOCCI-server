module AuthenticationStrategies
  # This is an example demonstrating the use of Warden in
  # authentication. Every strategy must extend `::Warden::Strategies::Base`
  # and implement the following methods:
  #
  #  valid?
  #  store?
  #  authenticate!
  #
  # Options from the strategy-specific configuration file are available
  # globally as `OPTIONS` (constant). Configuration files are located
  # in etc/auth_strategies/STRATEGY_NAME/ENV_NAME.yml
  class DummyStrategy < ::Warden::Strategies::Base

    # Checks whether this strategy is applicable or we should
    # move on to the next one. Incoming request is available in
    # `env`, you can get to it through ActionDispatch as follows:
    #
    #  ::ActionDispatch::Request.new(env)
    #
    # Here you should check required environment variables or
    # request headers necessary for this strategy to work.
    #
    # @return [TrueClass, FalseClass] valid or not
    def valid?
      Rails.logger.debug "[AuthN] [#{self.class}] Checking for applicability"
      Rails.logger.debug "[AuthN] [#{self.class}] Strategy is always applicable!"
      true
    end

    # Always include this!
    #
    # @return [TrueClass, FalseClass] always false
    def store?
      false
    end

    # Runs the actual authentication routine. Success or failure is
    # indicated by calling
    #
    #  success! user_object
    #
    # or
    #
    #  fail! string_reason
    #
    # You HAVE TO return IMMEDIATELY after calling `fail!`, this is very
    # important!
    def authenticate!
      Rails.logger.debug "[AuthN] [#{self.class}] Authenticating ..."

      if OPTIONS.block_all
        fail! 'BlockAll for DummyStrategy is active!'
        return
      end

      user = Hashie::Mash.new
      user.auth!.type = OPTIONS.fake_type || 'dummy'

      case user.auth.type
      when 'dummy', 'basic'
        user.auth!.credentials!.username = OPTIONS.fake_username || 'dummy_user'
        user.auth!.credentials!.password = OPTIONS.fake_password || 'dummy_password'
        user.identity = user.auth.credentials.username
      when 'x509', 'voms'
        user.auth!.credentials!.client_cert_dn = OPTIONS.fake_client_cert_dn || 'dummy_cert_dn'
        user.auth!.credentials!.client_cert = OPTIONS.fake_client_cert || 'dummy_cert'
        user.auth!.credentials!.client_cert_voms_attrs = OPTIONS.fake_voms_attrs || {}
        user.auth!.credentials!.issuer_cert_dn = OPTIONS.fake_issuer_cert_dn || 'dummy_issuer_cert_dn'
        user.auth!.credentials!.verification_status = OPTIONS.fake_verification_status || 'SUCCESS'
        user.identity = user.auth.credentials.client_cert_dn
      else
        user.identity = 'unknown'
        user.auth!.credentials = {}
      end

      Rails.logger.debug "[AuthN] [#{self.class}] Authenticated #{user.to_hash.inspect}"
      success! user.deep_freeze
    end
  end
end
