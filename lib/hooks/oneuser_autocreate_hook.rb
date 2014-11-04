module Hooks
  class OneuserAutocreateHook

    ALLOWED_AUTH_STRATEGIES = ['voms'].freeze

    def initialize(app, options)
      @app = app
      @options = options
      @vo_names = @options.vo_names.kind_of?(Array) ? @options.vo_names : @options.vo_names.split(' ')

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
          if old_or_new_user.nil? || old_or_new_user.blank?
            Rails.logger.debug "[Hooks] [OneuserAutocreateHook] Ignoring user " \
                               "#{user_struct.identity.inspect}, not eligible for " \
                               "autocreate"
          elsif old_or_new_user.is_new
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
      user_dn = get_first_dn_candidate(user_struct, @vo_names)
      return if user_dn.blank?
      user_dn = ::Backends::Opennebula::Authn::CloudAuth::X509Auth.escape_dn(user_dn)

      username = cloud_auth_client.get_username(user_dn)
      user = if username.nil?
        create_user(user_dn, user_struct)
      else
        get_user(username)
      end

      user
    end

    def cloud_auth_client
      conf = Hashie::Mash.new
      conf.auth = 'basic'
      conf.one_xmlrpc = @options.xmlrpc_endpoint

      conf.srv_auth = 'cipher'
      conf.srv_user = @options.username
      conf.srv_passwd = @options.password

      ::Backends::Opennebula::Authn::CloudAuthClient.new(conf)
    end

    def client
      cloud_auth_client.client
    end

    def user_pool
      ::OpenNebula::UserPool.new(client)
    end

    def group_pool
      ::OpenNebula::GroupPool.new(client)
    end

    def get_first_dn_candidate(user_struct, allowed_vo_names)
      return if allowed_vo_names.blank?

      credentials = user_struct.auth_.credentials
      return if credentials.blank?
      return if credentials[:client_cert_voms_attrs].blank? || credentials[:client_cert_dn].blank?

      # TODO: interate through all available sets of attrs?
      first_voms = credentials[:client_cert_voms_attrs].first
      return if first_voms[:vo].blank? || first_voms[:role].blank? || first_voms[:capability].blank?

      # apply VO restrictions
      return unless allowed_vo_names.include?(first_voms[:vo])

      # DN with VOMS attrs appended and whitespaces removed
      "#{credentials[:client_cert_dn]}/VO=#{first_voms[:vo]}/Role=#{first_voms[:role]}/Capability=#{first_voms[:capability]}"
    end

    def create_user(user_dn, user_struct)
      user = Hashie::Mash.new
      user.is_new = true
      user.username = ::Digest::SHA1.hexdigest(user_dn)

      one_user = ::OpenNebula::User.new(::OpenNebula::User.build_xml, client)
      rc = one_user.allocate(user.username, user_dn, ::OpenNebula::User::X509_AUTH)
      check_retval(rc)

      rc = one_user.info
      check_retval(rc)

      # TODO: add custom metadata

      one_group = get_group("users")
      rc = one_user.chgrp(one_group['ID'])
      check_retval(rc)

      user.group = one_group['NAME']
      user.id = one_user['ID']

      user
    end

    def get_user(username)
      user = Hashie::Mash.new
      user.is_new = false

      if @options.debug_mode
        # refresh the pool and select the right user
        rc = user_pool.info
        check_retval(rc)

        one_user = user_pool.select { |user| user['NAME'] == username }.first

        if one_user
          user.id = one_user['ID']
          user.username = one_user['NAME']
          user.group = one_user['GNAME']
        end
      end

      user
    end

    def get_group(groupname)
      # refresh the pool and select the right group
      rc = group_pool.info
      check_retval(rc)

      group_pool.select { |group| group['NAME'] == groupname }.first
    end

    def check_retval(rc)
      return true unless ::OpenNebula.is_error?(rc)

      Rails.logger.fatal "[Hooks] [OneuserAutocreateHook] Call to OpenNebula failed: #{rc.message}"

      case rc.errno
      when ::OpenNebula::Error::EAUTHENTICATION
        fail "AuthenticationError: #{rc.message}"
      when ::OpenNebula::Error::EAUTHORIZATION
        fail "AuthorizationError: #{rc.message}"
      when ::OpenNebula::Error::ENO_EXISTS
        fail "NotFoundError: #{rc.message}"
      when ::OpenNebula::Error::EACTION
        fail "ActionError: #{rc.message}"
      else
        fail "UnknownError: #{rc.message}"
      end
    end

  end
end
