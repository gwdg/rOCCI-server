module AuthenticationStrategies
  class VomsStrategy < ::Warden::Strategies::Base

    VOMS_RANGE = (0..100)
    GRST_CRED_REGEXP = /(.+)\s(\d+)\s(\d+)\s(\d)\s(.+)/
    GRST_VOMS_REGEXP = /\/(.+)\/Role=(.+)\/Capability=(.+)/

    def auth_request
      @auth_request ||= ::ActionDispatch::Request.new(env)
    end

    def store?
      false
    end

    def valid?
      Rails.logger.debug "[AuthN] [#{self.class}] Checking for the strategy applicability"
      Rails.logger.debug "[AuthN] [#{self.class}] SSL_CLIENT_S_DN: #{auth_request.env['SSL_CLIENT_S_DN'].inspect}"
      result = !auth_request.env['SSL_CLIENT_S_DN'].blank? && self.class.voms_extensions?(auth_request)

      Rails.logger.debug "[AuthN] [#{self.class}] Strategy is #{result ? '' : 'not '}applicable!"
      result
    end

    def authenticate!
      Rails.logger.debug "[AuthN] [#{self.class}] Authenticating #{auth_request.env['GRST_CRED_0'].inspect}"

      # Get user's DN
      proxy_cert_subject = GRST_CRED_REGEXP.match(auth_request.env['GRST_CRED_0'])[5]
      if proxy_cert_subject.blank?
        fail!('Could not extract user\'s DN from credentials!')
        return
      end

      # Get VOMS extension attributes
      voms_cert_attrs = self.class.voms_extension_attrs(auth_request)
      if voms_cert_attrs.empty?
        fail!('Could not extract VOMS attributes from user\'s credentials!')
        return
      end

      user = Hashie::Mash.new
      user.auth!.type = "voms"
      user.auth!.credentials!.client_cert_dn = proxy_cert_subject
      user.auth!.credentials!.client_cert_voms_attrs = voms_cert_attrs
      user.auth!.credentials!.client_cert = auth_request.env['SSL_CLIENT_CERT'] unless auth_request.env['SSL_CLIENT_CERT'].blank?
      user.auth!.credentials!.verification_status = auth_request.env['SSL_CLIENT_VERIFY']

      Rails.logger.debug "[AuthN] [#{self.class}] Authenticated #{user.to_hash.inspect}"
      success! user
    end

    class << self

      def voms_extensions?(auth_request)
        voms_ext = false

        VOMS_RANGE.each do |index|
          Rails.logger.debug "[AuthN] [#{self}] GRST_CRED_#{index}: \"" + auth_request.env["GRST_CRED_#{index}"].inspect + "\""
          break if auth_request.env["GRST_CRED_#{index}"].blank?

          if auth_request.env["GRST_CRED_#{index}"].start_with?('VOMS')
            voms_ext = true
            break
          end
        end

        voms_ext
      end

      def voms_extension_attrs(auth_request)
        attributes = []

        VOMS_RANGE.each do |index|
          break if auth_request.env["GRST_CRED_#{index}"].blank?

          if auth_request.env["GRST_CRED_#{index}"].start_with?('VOMS')
            # Parse the extension and drop useless first element of MatchData
            voms_ext = GRST_CRED_REGEXP.match(auth_request.env["GRST_CRED_#{idx}"])
            voms_ext = voms_ext.to_a.drop 1

            # Parse group, role and capability from the VOMS extension
            voms_ary = GRST_VOMS_REGEXP.match(voms_ext[4])
            voms_ary = voms_ary.to_a.drop 1

            voms_attrs = Hashie::Mash.new
            voms_attrs.vo = voms_ary[0]
            voms_attrs.role = voms_ary[1]
            voms_attrs.capability = voms_ary[2]

            attributes << voms_attrs
          end
        end

        Rails.logger.debug "[AuthN] [#{self}] VOMS attrs: #{attributes.inspect}"
        attributes
      end

    end

  end
end