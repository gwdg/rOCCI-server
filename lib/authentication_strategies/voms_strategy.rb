module AuthenticationStrategies
  class VomsStrategy < ::Warden::Strategies::Base
    VOMS_RANGE = (0..100)
    GRST_CRED_REGEXP = /^(.+)\s(\d+)\s(\d+)\s(\d)\s(.+)$/
    GRST_VOMS_REGEXP = /^\/(.+)\/Role=(.+)\/Capability=(.+)$/
    ROBOT_SUBPROXY_REGEXP = /^(?<issuer_base>\/.+)\/CN=Robot(:|\/|\s\-\s)(?<robot_name>[^\/]+)\/CN=eToken:(?<subuser_name>[^\/]+)(\/CN=\d+)+$/

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
      result = !auth_request.env['SSL_CLIENT_S_DN'].blank? && self.class.voms_extensions?(auth_request)

      Rails.logger.debug "[AuthN] [#{self.class}] Strategy is #{result ? '' : 'not '}applicable!"
      result
    end

    # @see AuthenticationStrategies::DummyStrategy
    def authenticate!
      Rails.logger.debug "[AuthN] [#{self.class}] Authenticating #{auth_request.env['GRST_CRED_0'].inspect}"

      # Get user's DN
      proxy_cert_subject = (GRST_CRED_REGEXP.match(auth_request.env['GRST_CRED_0']) || [])[5]
      if proxy_cert_subject.blank?
        fail! 'Could not extract user\'s DN from credentials!'
        return
      end

      # Get VOMS extension attributes
      voms_cert_attrs = self.class.voms_extension_attrs(auth_request)
      if voms_cert_attrs.empty?
        fail! 'Could not extract VOMS attributes from user\'s credentials!'
        return
      end

      user = Hashie::Mash.new
      user.auth!.type = 'voms'
      user.auth!.credentials!.client_cert_dn = proxy_cert_subject
      user.auth!.credentials!.client_cert_voms_attrs = voms_cert_attrs
      user.auth!.credentials!.client_cert = auth_request.env['SSL_CLIENT_CERT'] unless auth_request.env['SSL_CLIENT_CERT'].blank?
      user.auth!.credentials!.verification_status = auth_request.env['SSL_CLIENT_VERIFY']

      # Use sub-proxy DN as user identity if we are handling robots
      # and the DN in question matches our restrictions
      user.identity = if self.class.handle_robots? && (matched_robot = auth_request.env['SSL_CLIENT_S_DN'].match(ROBOT_SUBPROXY_REGEXP))
                        etoken = self.class.extract_robot_etoken(matched_robot, auth_request)
                        if etoken.blank?
                          fail! 'Couldn\'t extract the first proxy DN of a robot certificate!'
                          return
                        end

                        etoken
                      else
                        user.auth.credentials.client_cert_dn
                      end

      Rails.logger.debug "[AuthN] [#{self.class}] Authenticated #{user.to_hash.inspect}"
      success! user.deep_freeze
    end

    class << self

      def extract_robot_etoken(matched_robot, auth_request)
        Rails.logger.debug "[AuthN] [#{self}] Matched robot #{matched_robot[:robot_name].inspect} " \
                           "and sub-user #{matched_robot[:subuser_name].inspect}"
        w_etoken = GRST_CRED_REGEXP.match(auth_request.env["GRST_CRED_1"])
        w_etoken = w_etoken.to_a.drop 1

        Rails.logger.debug "[AuthN] [#{self}] Looking at GRST_CRED_1 => " \
                           "#{auth_request.env["GRST_CRED_1"].inspect} and its last " \
                           "element => #{w_etoken[4].inspect}"
        w_etoken[4]
      end

      def voms_extensions?(auth_request)
        voms_ext = false

        VOMS_RANGE.each do |index|
          Rails.logger.debug "[AuthN] [#{self}] GRST_CRED_#{index}: " + auth_request.env["GRST_CRED_#{index}"].inspect
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
            voms_ext = GRST_CRED_REGEXP.match(auth_request.env["GRST_CRED_#{index}"])
            voms_ext = voms_ext.to_a.drop 1
            break if voms_ext.empty?

            # Parse group, role and capability from the VOMS extension
            voms_ary = GRST_VOMS_REGEXP.match(voms_ext[4])
            voms_ary = voms_ary.to_a.drop 1
            break if voms_ary.empty?

            voms_attrs = Hashie::Mash.new
            voms_attrs.vo = mapped_vo_name(voms_ary[0])
            voms_attrs.role = voms_ary[1]
            voms_attrs.capability = voms_ary[2]

            if allowed_access?(voms_attrs.vo)
              attributes << voms_attrs
            else
              Rails.logger.warn "[AuthN] [#{self}] VO #{voms_attrs.vo.inspect} is NOT allowed!"
            end
          end
        end

        Rails.logger.debug "[AuthN] [#{self}] VOMS attrs: #{attributes.inspect}"
        attributes
      end

      def allowed_access?(vo_name)
        return false if vo_name.blank?

        case OPTIONS.access_policy
        when 'blacklist'
          !blacklisted_vo?(vo_name)
        when 'whitelist'
          whitelisted_vo?(vo_name)
        else
          raise Errors::ConfigurationParsingError,
                "Unsupported VOMS access policy #{OPTIONS.access_policy.inspect}!"
        end
      end

      def blacklisted_vo?(vo_name)
        blacklist = AuthenticationStrategies::Helpers::YamlHelper.read_yaml(OPTIONS.blacklist) || []
        blacklist.include?(vo_name)
      end

      def whitelisted_vo?(vo_name)
        whitelist = AuthenticationStrategies::Helpers::YamlHelper.read_yaml(OPTIONS.whitelist) || []
        whitelist.include?(vo_name)
      end

      def mapped_vo_name(vo_name)
        return vo_name unless OPTIONS.vo_mapping

        map = AuthenticationStrategies::Helpers::YamlHelper.read_yaml(OPTIONS.vo_mapfile) || {}
        new_vo_name = map[vo_name] || vo_name

        Rails.logger.debug "[AuthN] [#{self}] VO name mapped #{vo_name.inspect} -> #{new_vo_name.inspect}"
        new_vo_name
      end

      def handle_robots?
        OPTIONS.robot_subproxy_identity
      end
    end
  end
end
