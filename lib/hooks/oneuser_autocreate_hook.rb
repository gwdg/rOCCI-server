module Hooks
  class OneuserAutocreateHook

    ALLOWED_AUTH_STRATEGIES = ['voms'].freeze

    def initialize(app, options)
      @app = app
      @options = options
      @vo_names = @options.vo_names.kind_of?(Array) ? @options.vo_names : @options.vo_names.split(' ')

      init_cloud_auth_client
      init_client

      Rails.logger.debug "[Hooks] [OneuserAutocreateHook] Enabling autocreate for " \
                         "authentication strategies #{ALLOWED_AUTH_STRATEGIES.inspect} " \
                         "with VOs #{@vo_names.inspect}"
    end

    def call(env)
      request = ::ActionDispatch::Request.new(env)

      unless @vo_names.blank?
        # trigger Warden early to get user information
        request.env['warden'].authenticate!
        user_struct = request.env['warden'].user || ::Hashie::Mash.new

        # attempt autocreate for eligible users
        Rails.logger.debug "[Hooks] [OneuserAutocreateHook] Evaluating incoming " \
                           "user: #{user_struct.inspect}"
        if ALLOWED_AUTH_STRATEGIES.include?(user_struct.auth_.type)
          old_or_new_user = get_or_create(user_struct)

          # did we create a new user?
          if old_or_new_user.is_new
            Rails.logger.warn "[Hooks] [OneuserAutocreateHook] Created new user for " \
                              "#{user_struct.identity.inspect} as " \
                              "ID: #{old_or_new_user.id.inspect} " \
                              "NAME: #{old_or_new_user.username.inspect} " \
                              "GROUP: #{old_or_new_user.group.inspect}"
          else
            Rails.logger.debug "[Hooks] [OneuserAutocreateHook] Ignoring user " \
                               "#{user_struct.identity.inspect}, already exists as " \
                               "ID: #{old_or_new_user.id.inspect} " \
                               "NAME: #{old_or_new_user.username.inspect} " \
                               "GROUP: #{old_or_new_user.group.inspect}"
          end
        else
          Rails.logger.debug "[Hooks] [OneuserAutocreateHook] Ignoring " \
                             "#{user_struct.identity.inspect}, unsupported authentication strategy"
        end
      end

      # pass control back to the application
      @app.call(env)
    end

    private

    def get_or_create(user_struct)
      username = get_first_dn_candidate(user_struct)
      return if username.blank?

      username = @cloud_auth_client.get_username(::Backends::Opennebula::Authn::CloudAuth::X509Auth.escape_dn(username))
      if username.nil?
        user = Hashie::Mash.new
        user.id = "bla"
        user.username = "blabla"
        user.group = "blablabla"

        user.is_new = true
      else
        user = Hashie::Mash.new
        user.id = "bla"
        user.username = "blabla"
        user.group = "blablabla"

        user.is_new = false
      end

      user
    end

    def init_cloud_auth_client
      @cloud_auth_client ||= begin
        conf = Hashie::Mash.new
        conf.auth = 'basic'
        conf.one_xmlrpc = @options.xmlrpc_endpoint

        conf.srv_auth = 'cipher'
        conf.srv_user = @options.username
        conf.srv_passwd = @options.password

        ::Backends::Opennebula::Authn::CloudAuthClient.new(conf)
      end
    end

    def init_client
      @client ||= begin
        init_cloud_auth_client.client
      end
    end

    def get_first_dn_candidate(user_struct)
      credentials = user_struct.auth_.credentials
      return if credentials.blank?
      return if credentials[:client_cert_voms_attrs].blank? || credentials[:client_cert_dn].blank?

      # TODO: interate through all available sets of attrs?
      first_voms = credentials[:client_cert_voms_attrs].first
      return if first_voms[:vo].blank? || first_voms[:role].blank? || first_voms[:capability].blank?

      # DN with VOMS attrs appended and whitespaces removed
      "#{credentials[:client_cert_dn]}/VO=#{first_voms[:vo]}/Role=#{first_voms[:role]}/Capability=#{first_voms[:capability]}"
    end

  end
end
