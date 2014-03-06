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
    ALLOWED_MAPPING_TYPES = [:user, :tenant].freeze

    def auth_request
      @auth_request ||= ::ActionDispatch::Request.new(env)
    end

    # @see AuthenticationStrategies::DummyStrategy
    def store?
      false
    end

    # @see AuthenticationStrategies::DummyStrategy
    def valid?
      Rails.logger.debug "[AuthN] [#{self.class}] Checking for applicability"
      result = !auth_request.headers['X-Auth-Token'].blank? && self.class.have_certs?

      Rails.logger.debug "[AuthN] [#{self.class}] Strategy is #{result ? '' : 'not '}applicable!"
      result
    end

    # @see AuthenticationStrategies::DummyStrategy
    def authenticate!
      Rails.logger.debug "[AuthN] [#{self.class}] Authenticating with X-Auth-Token"

      if self.class.revoked_token?(auth_request.headers['X-Auth-Token'])
        fail! 'Your Keystone token has been revoked!'
        return
      end

      store = self.class.init_x509_store(
        OPTIONS.keystone_pki_trust.ca_cert,
        OPTIONS.keystone_pki_trust.ca_path
      )

      crt = OpenSSL::X509::Certificate.new(File.read(OPTIONS.keystone_pki_trust.signing_cert))

      verified = begin
        cms_token = OpenSSL::CMS.read_cms(self.class.keystone2cms(auth_request.headers['X-Auth-Token']))
        cms_token.verify([crt], store, nil, nil)
      rescue => e
        Rails.logger.warn "[AuthN] [#{self.class}] OpenSSL::CMS validation " \
                          "failed with #{e.message.inspect} on: #{auth_request.headers['X-Auth-Token']}"
        fail! 'Your Keystone token is invalid!'
        return
      end

      unless verified
        fail! 'Failed to verify your Keystone token!'
        return
      end

      extracted_token = self.class.extract_token(cms_token)
      unless extracted_token
        fail! 'Your Keystone token is expired or malformed!'
        return
      end

      unless self.class.allowed_access?(extracted_token.access_.token_.tenant_.name)
        fail! "Tenant #{extracted_token.access_.token_.tenant_.name.inspect} is not allowed!"
        return
      end

      user = self.class.user_factory(extracted_token)
      unless user
        fail! 'Couldn\'t retrieve user and tenant information from the token!'
        return
      end

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

        result = file_marcopolo?(OPTIONS.keystone_pki_trust_.ca_cert) && file_marcopolo?(OPTIONS.keystone_pki_trust_.signing_cert)

        Rails.logger.warn "[AuthN] [#{self.name}] Certificates are not present or empty! Bailing out ..." unless result
        result
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

      def extract_token(cms_token)
        begin
          data = Hashie::Mash.new(JSON.parse(cms_token.data))
          expired_token?(data) ? nil : data
        rescue => e
          Rails.logger.error "[AuthN] [#{self.name}] Failed to " \
                             "extract data from CMS token! #{e.message}"
          raise e
        end
      end

      def revoked_token?(original_token)
        return false unless OPTIONS.keystone_pki_trust.trl_url
        trl = get_trl(OPTIONS.keystone_pki_trust.trl_url)
        return true unless trl && trl.revoked

        token_md5 = Digest::MD5.digest(original_token)
        trl.revoked.select { |rev| rev.id == token_md5 }.any?
      end

      def expired_token?(extracted_token)
        exp_time = extracted_token.access_.token_.expires
        return true unless exp_time
        DateTime.iso8601(exp_time) < DateTime.now
      end

      def get_trl(url)
        dalli = Backend.dalli_instance_factory(
          "keystone_strategy_trl_cache",
          get_memcaches, { expire_after: 2.minutes },
          url.gsub(/\W+/, '_')
        )

        trl_parsed = nil
        begin
          unless trl = dalli.get('trl')
            trl = open(url).read
            dalli.set('trl', trl)
          end

          trl_parsed = Hashie::Mash.new(JSON.parse(trl))
        rescue => e
          Rails.logger.error "[AuthN] [#{self.name}] Failed to " \
                             "retrieve and parse TRL from #{url.inspect}! #{e.message}"
          dalli.delete('trl')
          raise e
        end

        trl_parsed
      end

      def get_memcaches
        return unless OPTIONS.memcaches
        OPTIONS.memcaches.respond_to?(:each) ? OPTIONS.memcaches : OPTIONS.memcaches.split
      end

      def user_factory(extracted_token)
        return if extracted_token.access_.token_.tenant_.name.blank?
        return if extracted_token.access_.user_.username.blank?

        user = Hashie::Mash.new
        user.auth!.type = 'keystone'
        user.auth!.credentials!.tenant = mapped_name(extracted_token.access.token.tenant.name, :tenant)
        user.auth!.credentials!.username = mapped_name(extracted_token.access.user.username, :user)
        user.auth!.credentials!.token = extracted_token
        user.auth!.credentials!.verification_status = 'SUCCESS'

        user
      end

      def file_marcopolo?(path)
        return false if path.blank?
        File.readable?(path) && !File.zero?(path)
      end

      def allowed_access?(tenant_name)
        return false if tenant_name.blank?

        case OPTIONS.access_policy
        when 'blacklist'
          !blacklisted_tenant?(tenant_name)
        when 'whitelist'
          whitelisted_tenant?(tenant_name)
        else
          raise Errors::ConfigurationParsingError,
                "Unsupported Keystone access policy #{OPTIONS.access_policy.inspect}!"
        end
      end

      def blacklisted_tenant?(tenant_name)
        blacklist = AuthenticationStrategies::Helpers::YamlHelper.read_yaml(OPTIONS.blacklist) || []
        blacklist.include?(tenant_name)
      end

      def whitelisted_tenant?(tenant_name)
        whitelist = AuthenticationStrategies::Helpers::YamlHelper.read_yaml(OPTIONS.whitelist) || []
        whitelist.include?(tenant_name)
      end

      def mapped_name(name, type)
        raise "Unsupported mapping request! Type #{type.to_s.inspect} " \
              "is not registered!" unless ALLOWED_MAPPING_TYPES.include?(type)
        return name unless OPTIONS.send("#{type.to_s}_mapping")

        map = AuthenticationStrategies::Helpers::YamlHelper.read_yaml(OPTIONS.send("#{type.to_s}_mapfile")) || {}
        new_name = map[name] || name

        Rails.logger.debug "[AuthN] [#{self}] #{type.to_s.capitalize} name mapped #{name.inspect} -> #{new_name.inspect}"
        new_name
      end
    end
  end
end
