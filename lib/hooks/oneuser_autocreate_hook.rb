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
      # get the request and explore it
      request = ::ActionDispatch::Request.new(env)
      start_autocreate(request) unless @vo_names.blank?

      # pass control back to the application
      @app.call(env)
    end

    private

    def start_autocreate(request)
      # trigger Warden early to get user information
      request.env['warden'].authenticate!
      user_struct = request.env['warden'].user || ::Hashie::Mash.new

      # should we do something here?
      unless ALLOWED_AUTH_STRATEGIES.include?(user_struct.auth_.type)
        Rails.logger.debug "[Hooks] [OneuserAutocreateHook] Ignoring " \
                           "#{user_struct.identity.inspect}, " \
                           "not using #{ALLOWED_AUTH_STRATEGIES.inspect}"

        return
      end

      # pass it along
      Rails.logger.debug "[Hooks] [OneuserAutocreateHook] Evaluating incoming " \
                         "user: #{user_struct.inspect}"
      do_autocreate(user_struct)
    end

    def do_autocreate(user_struct)
      # do not proceed if warden didn't provide user data
      return if user_struct.blank?

      # attempt autocreate for eligible users
      user_account = perform_get_or_create(user_struct)
      if user_account.nil? || user_account.blank?
        Rails.logger.debug "[Hooks] [OneuserAutocreateHook] Ignoring user " \
                           "#{user_struct.identity.inspect}, not eligible for " \
                           "autocreate"
      elsif user_account.is_new
        Rails.logger.warn "[Hooks] [OneuserAutocreateHook] Created new user for " \
                          "#{user_struct.identity.inspect} as " \
                          "ID: #{user_account.id.inspect} " \
                          "NAME: #{user_account.username.inspect} " \
                          "GROUP: #{user_account.group.inspect}"
      elsif @options.debug_mode
        Rails.logger.debug "[Hooks] [OneuserAutocreateHook] Ignoring user " \
                           "#{user_struct.identity.inspect}, already exists as " \
                           "ID: #{user_account.id.inspect} " \
                           "NAME: #{user_account.username.inspect} " \
                           "GROUP: #{user_account.group.inspect}"
      end

      true
    end

    def perform_get_or_create(user_struct)
      # process user data and get an augmented DN and VO info
      identity = get_first_identity_candidate(user_struct, @vo_names)
      return if identity.blank?

      # look-up account in ONE
      identity.dn = ::Backends::Opennebula::Authn::CloudAuth::X509Auth.escape_dn(identity.dn)
      username = cloud_auth_client.get_username(identity.dn)

      username.blank? ? create_account(identity, user_struct) : get_account(username)
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

    def get_first_identity_candidate(user_struct, allowed_vo_names)
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
      identity = Hashie::Mash.new
      identity.dn = "#{credentials[:client_cert_dn]}/VO=#{first_voms[:vo]}/Role=#{first_voms[:role]}/Capability=#{first_voms[:capability]}"
      identity.vo = first_voms[:vo]
      identity.base_dn = credentials[:client_cert_dn]

      identity
    end

    def create_account(identity, user_struct)
      user = Hashie::Mash.new
      user.is_new = true
      user.username = ::Digest::SHA1.hexdigest(identity.dn)

      one_user = ::OpenNebula::User.new(::OpenNebula::User.build_xml, client)
      rc = one_user.allocate(user.username, identity.dn, ::OpenNebula::User::X509_AUTH)
      check_retval(rc)

      rc = one_user.info
      check_retval(rc)

      # TODO: add custom metadata, at least X509_DN = identity.base_dn

      one_group = get_group(identity.vo)
      unless one_group
        Rails.logger.warn "[Hooks] [OneuserAutocreateHook] Group #{identity.vo.inspect} " \
                          "doesn't exists, user could not be created automatically"
        return
      end

      rc = one_user.chgrp(one_group['ID'])
      check_retval(rc)

      user.group = one_group['NAME']
      user.id = one_user['ID']

      user
    end

    def get_account(username)
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
