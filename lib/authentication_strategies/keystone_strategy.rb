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
    SUPPORTED_CERT_SOURCES = %w(file).freeze

    def auth_request
      @auth_request ||= ::ActionDispatch::Request.new(env)
    end

    def store?
      false
    end

    def valid?
      Rails.logger.debug "[AuthN] [#{self.class}] Checking for the strategy applicability"
      result = !auth_request.headers['X-Auth-Token'].blank? && self.class.have_certs?

      Rails.logger.debug "[AuthN] [#{self.class}] Strategy is #{result ? '' : 'not '}applicable!"
      result
    end

    def authenticate!
      Rails.logger.debug "[AuthN] [#{self.class}] Authenticating with X-Auth-Token"

      # TODO: impl. ca_path
      store = self.class.init_x509_store(
        OPTIONS.keystone_pki_trust.ca_cert,
        OPTIONS.keystone_pki_trust.ca_path
      )

      crt = OpenSSL::X509::Certificate.new(File.read(OPTIONS.keystone_pki_trust.signing_cert))

      cms_token = OpenSSL::CMS.read_cms(keystone2cms(auth_request.headers['X-Auth-Token']))
      verified = cms_token.verify([crt], store, nil, nil)

      unless verified
        fail!('Failed to verify your Keystone token!')
        return
      end

      extracted_token = self.class.extract_and_validate_token(cms_token)
      unless extracted_token
        fail!('Your Keystone token is either expired or malformed!')
        return
      end

      # TODO: impl. ACLs
      user = self.class.user_factory(extracted_token)
      Rails.logger.debug "[AuthN] [#{self.class}] Authenticated #{user.to_hash.inspect}"
      success! user
    end

    class << self
      def have_certs?
        # TODO: implement 'url' as a cert_source option
        unless SUPPORTED_CERT_SOURCES.include?(OPTIONS.keystone_pki_trust_.cert_source)
          raise Errors::ConfigurationParsingError,
                "Unsupported cert_source #{OPTIONS.keystone_pki_trust_.cert_source.inspect} for Keystone! " \
                "Only #{SUPPORTED_CERT_SOURCES.join(', ').inspect} are allowed!"
        end

        file_marcopolo?(OPTIONS.keystone_pki_trust_.ca_cert) && file_marcopolo?(OPTIONS.keystone_pki_trust_.signing_cert)
      end

      def keystone2cms(token)
        # Wrap lines to 64 chars per line
        ary = token.scan(/.{64}/)
        size_rest = token.length - (ary.length*64)
        ary << token.scan(Regexp.new(".{#{size_rest}}$"))
        ary.flatten!
        token = ary.join("\n")

        # Fix some OS Keystone stuff (why??)
        token.gsub!('-', '/')

        # Add CMS header & trailer
        "-----BEGIN CMS-----\n#{token}\n-----END CMS-----\n"
      end

      def init_x509_store(ca_cert, ca_path = nil)
        store = OpenSSL::X509::Store.new
        store.add_path(ca_path) unless ca_path.blank?

        ca_crt = OpenSSL::X509::Certificate.new(File.read(ca_cert))
        store.add_cert ca_crt

        store
      end

      def extract_and_validate_token(cms_token)
        begin
          data = Hashie::Mash.new(cms_token.data)
          valid_token?(data) ? data : nil
        rescue => e
          Rails.logger.error "[AuthN] [#{self.class}] Failed to " \
                             "extract and validate CMS token! #{e.message}"
          nil
        end
      end

      def valid_token?(extracted_token)
        !expired_token?(extracted_token) && !revoked_token?(extracted_token)
      end

      def revoked_token?(extracted_token)
        return false unless OPTIONS.keystone_pki_trust.trl_url
        # TODO: impl.
        true
      end

      def expired_token?(extracted_token)
        exp_time = extracted_token.access_.token_.expires
        return true unless exp_time
        DateTime.iso8601(exp_time) > DateTime.now
      end

      def user_factory(extracted_token)
        # TODO: impl. mapping for username & tenant
        user = Hashie::Mash.new
        user.auth!.type = 'keystone'
        user.auth!.credentials!.tenant = ""
        user.auth!.credentials!.username = ""
        user.auth!.credentials!.token = extracted_token
        user.auth!.credentials!.verification_status = 'SUCCESS'

        user
      end

      def file_marcopolo?(path)
        return false if path.blank?
        File.readable?(path) && !File.zero?(path)
      end
    end
  end
end
