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

      if OPTIONS.block_all
        fail! 'BlockAll for DummyStrategy is active!'
        return
      end

      user = Hashie::Mash.new
      user.auth!.type = OPTIONS.fake_type || "dummy"

      case user.auth.type
      when "dummy", "basic"
        user.auth!.credentials!.username = OPTIONS.fake_username || "dummy_user"
        user.auth!.credentials!.password = OPTIONS.fake_password || "dummy_password"
      when "x509", "voms"
        user.auth!.credentials!.client_cert_dn = OPTIONS.fake_client_cert_dn || "dummy_cert_dn"
        user.auth!.credentials!.client_cert = OPTIONS.fake_client_cert || "dummy_cert"
        user.auth!.credentials!.client_cert_voms_attrs = OPTIONS.fake_voms_attrs || {}
        user.auth!.credentials!.issuer_cert_dn = OPTIONS.fake_issuer_cert_dn || "dummy_issuer_cert_dn"
        user.auth!.credentials!.verification_status = OPTIONS.fake_verification_status || "SUCCESS"
      else
        user.auth!.credentials = {}
      end

      Rails.logger.debug "[AuthN] [#{self.class}] Authenticated #{user.to_hash.inspect}"
      success! user
    end

  end
end