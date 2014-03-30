module AuthenticationStrategies
  class X509Strategy < ::Warden::Strategies::Base
    def auth_request
      @auth_request ||= ::ActionDispatch::Request.new(env)
    end

    # @see AuthenticationStrategies::DummyStrategy
    def store?
      false
    end

    # @see AuthenticationStrategies::DummyStrategy
    def valid?
      # TODO: verify that we are running inside Apache2
      Rails.logger.debug "[AuthN] [#{self.class}] Checking for applicability"
      Rails.logger.debug "[AuthN] [#{self.class}] SSL_CLIENT_S_DN: #{auth_request.env['SSL_CLIENT_S_DN'].inspect}"
      result = !(auth_request.env['SSL_CLIENT_S_DN'].blank? || VomsStrategy.voms_extensions?(auth_request))

      Rails.logger.debug "[AuthN] [#{self.class}] Strategy is #{result ? '' : 'not '}applicable!"
      result
    end

    # @see AuthenticationStrategies::DummyStrategy
    def authenticate!
      Rails.logger.debug "[AuthN] [#{self.class}] Authenticating ..."

      unless auth_request.env['SSL_CLIENT_VERIFY'] == 'SUCCESS'
        fail! "The verification process has failed! SSL_CLIENT_VERIFY = #{auth_request.env['SSL_CLIENT_VERIFY'].inspect}"
        return
      end

      user = Hashie::Mash.new
      user.auth!.type = 'x509'
      user.auth!.credentials!.client_cert_dn = auth_request.env['SSL_CLIENT_S_DN']
      user.auth!.credentials!.client_cert = auth_request.env['SSL_CLIENT_CERT'] unless auth_request.env['SSL_CLIENT_CERT'].blank?
      user.auth!.credentials!.issuer_cert_dn = auth_request.env['SSL_CLIENT_I_DN']
      user.auth!.credentials!.verification_status = auth_request.env['SSL_CLIENT_VERIFY']
      user.identity = user.auth.credentials.client_cert_dn

      Rails.logger.debug "[AuthN] [#{self.class}] Authenticated #{user.to_hash.inspect}"
      success! user.deep_freeze
    end
  end
end
