module AuthenticationStrategies
  class X509Strategy < ::Warden::Strategies::Base
    def auth_request
      @auth_request ||= ::ActionDispatch::Request.new(env)
    end

    def store?
      false
    end

    def valid?
      # TODO: verify that we are running inside Apache2
      Rails.logger.debug "[AuthN] [#{self.class}] Checking for the strategy applicability"
      !(auth_request.env['SSL_CLIENT_S_DN'].blank? || VomsStrategy.voms_extensions?(auth_request))
    end

    def authenticate!
      Rails.logger.debug "[AuthN] [#{self.class}] Authenticating ..."

      unless auth_request.env['SSL_CLIENT_VERIFY'] == 'SUCCESS'
        fail!("The verification process has failed! SSL_CLIENT_VERIFY = #{auth_request.env['SSL_CLIENT_VERIFY'].inspect}")
        return
      end

      user = Hashie::Mash.new
      user.auth!.type = 'x509'
      user.auth!.credentials!.client_cert_dn = auth_request.env['SSL_CLIENT_S_DN']
      user.auth!.credentials!.client_cert = auth_request.env['SSL_CLIENT_CERT'] unless auth_request.env['SSL_CLIENT_CERT'].blank?
      user.auth!.credentials!.issuer_cert_dn = auth_request.env['SSL_CLIENT_I_DN']
      user.auth!.credentials!.verification_status = auth_request.env['SSL_CLIENT_VERIFY']

      Rails.logger.debug "[AuthN] [#{self.class}] Authenticated #{user.to_hash.inspect}"
      success! user
    end
  end
end
