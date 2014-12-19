module Hooks
  class OneuserAutocreateHook

    ALLOWED_AUTH_STRATEGIES = ['voms'].freeze

    # Instantiates the hook with some pre-processing done on
    # provided +options+.
    #
    # @param app [Object] application object
    # @param options [Hashie::Mash] options in a hash-like structure
    def initialize(app, options)
      @app = app
      @options = options
      @vo_names = @options.vo_names.kind_of?(Array) ? @options.vo_names : @options.vo_names.split(' ')

      Rails.logger.debug "[Hooks] [OneuserAutocreateHook] Enabling autocreate for " \
                         "authentication strategies #{ALLOWED_AUTH_STRATEGIES.inspect} " \
                         "with VOs #{@vo_names.inspect}"
    end

    # Trigger hook execution for a specific incoming request
    # represented by +env+. After the hook has been executed
    # the control is passed back to the application.
    #
    # @param env [Object] request environment
    def call(env)
      # get the request and explore it
      request = ::ActionDispatch::Request.new(env)
      start_autocreate(request) unless @vo_names.blank?

      # pass control back to the application
      @app.call(env)
    end

    private

    # Starts the autocreate process by triggering early authentication in Warden and
    # validating the authentication strategy used by the user. Only strategies specified
    # in +ALLOWED_AUTH_STRATEGIES+ are allowed.
    #
    # @param request [ActionDispatch::Request] incoming request containing user data
    def start_autocreate(request)
      # trigger Warden early to get user information
      request.env['warden'].authenticate!
      user_struct = request.env['warden'].user || ::Hashie::Mash.new

      # do not proceed if warden didn't provide user data
      if user_struct.blank?
        Rails.logger.error "[Hooks] [OneuserAutocreateHook] Warden " \
                           "failed to provide user data, exiting"

        return
      end

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

    # Wraps the actual autocreate logic and provides detailed logging.
    #
    # @param user_struct [Hashie::Mash] user data in a hash-like structure
    def do_autocreate(user_struct)
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
      else
        Rails.logger.debug "[Hooks] [OneuserAutocreateHook] Ignoring user " \
                           "#{user_struct.identity.inspect}"
      end

      true
    end

    # Creates a temporary user identity based on provided credentials
    # and triggers a look-up in OpenNebula. If the given user account
    # doesn't exist, it will be created.
    #
    # @param user_struct [Hashie::Mash] user data in a hash-like structure
    # @return [Hashie::Mash, NilClass] user account info or +nil+ on failure
    def perform_get_or_create(user_struct)
      # process user data and get an augmented DN and VO info
      # TODO: is this the right approach? using the most generic credentials?
      identity = get_first_identity_candidate(user_struct, @vo_names)
      return if identity.blank?

      # look-up account in ONE
      identity.dn = ::Backends::Opennebula::Authn::CloudAuth::X509Auth.escape_dn(identity.dn)
      username = cloud_auth_client.send(:get_username, identity.dn)

      username.blank? ? create_account(identity, user_struct) : get_account(username)
    end

    # Creates a server-side connection to OpenNebula, with a privileged identity.
    # Such instance can be used only for authentication purposes and delegation.
    #
    # @return [Backends::Opennebula::Authn::CloudAuthClient] updated instance of the server-side client
    def cloud_auth_client
      conf = Hashie::Mash.new
      conf.auth = 'basic'
      conf.one_xmlrpc = @options.xmlrpc_endpoint

      conf.srv_auth = 'cipher'
      conf.srv_user = @options.username
      conf.srv_passwd = @options.password

      cloud_auth_client = ::Backends::Opennebula::Authn::CloudAuthClient.new(conf)
      cloud_auth_client.send :update_userpool_cache

      cloud_auth_client
    end

    # Generates a privileged client for OpenNebula. Such instance can
    # be used for executing ordinary actions.
    #
    # @return [OpenNebula::Client] client instance
    def client
      cloud_auth_client.client
    end

    # Creates a user pool instance already connected to OpenNebula's XML-RPC.
    #
    # @return [OpenNebula::UserPool] user pool instance
    def user_pool
      user_pool = ::OpenNebula::UserPool.new(client)
      check_retval user_pool.info

      user_pool
    end

    # Creates a group pool instance already connected to OpenNebula's XML-RPC.
    #
    # @return [OpenNebula::GroupPool] group pool instance
    def group_pool
      group_pool = ::OpenNebula::GroupPool.new(client)
      check_retval group_pool.info

      group_pool
    end

    # Creates an OpenNebula-compatible user identity from raw user
    # credentials provided by Warden. This method will return +nil+
    # if anything went wrong or this identity is not eligible for
    # autocreate.
    #
    # @param user_struct [Hashie::Mash] raw user data in a hash-like structure
    # @param allowed_vo_names [Array] a list of allowed VO names
    # @return [Hashie::Mash, NilClass] processed user identity or +nil+ on failure
    def get_first_identity_candidate(user_struct, allowed_vo_names)
      # should we even continue?
      if allowed_vo_names.blank?
        Rails.logger.warn "[Hooks] [OneuserAutocreateHook] This hook is enabled but no " \
                          "allowed VOs were configured, exiting"

        return
      end

      # validate incoming credentials, check required attributes
      credentials = user_struct.auth_.credentials
      if credentials.blank? || credentials[:client_cert_voms_attrs].blank? || credentials[:client_cert_dn].blank?
        Rails.logger.error "[Hooks] [OneuserAutocreateHook] User data from Warden did not " \
                           "contain required credential information, exiting"

        return
      end

      unless credentials[:verification_status] == 'SUCCESS'
        Rails.logger.error "[Hooks] [OneuserAutocreateHook] User data from Warden claims that " \
                           "credentials were not verified properly, exiting"

        return
      end

      # TODO: iterate through all available sets of attrs?
      first_voms = credentials[:client_cert_voms_attrs].first
      if first_voms[:vo].blank? || first_voms[:role].blank? || first_voms[:capability].blank?
        Rails.logger.error "[Hooks] [OneuserAutocreateHook] User data from Warden is missing " \
                           "vital VOMS-related attributes, exiting"

        return
      end

      # apply VO restrictions
      unless allowed_vo_names.include?(first_voms[:vo])
        Rails.logger.info "[Hooks] [OneuserAutocreateHook] VO #{first_voms[:vo].inspect} is " \
                           "not among the allowed VOs #{allowed_vo_names.inspect}, exiting"

        return
      end

      # DN with VOMS attrs appended and whitespaces removed
      identity = Hashie::Mash.new
      identity.dn = "#{credentials[:client_cert_dn]}" \
                    "/VO=#{first_voms[:vo]}" \
                    "/Role=#{first_voms[:role]}" \
                    "/Capability=#{first_voms[:capability]}"
      identity.vo = first_voms[:vo]
      identity.base_dn = credentials[:client_cert_dn]

      Rails.logger.debug "[Hooks] [OneuserAutocreateHook] Generated identity metadata " \
                         "for #{user_struct.identity.inspect}: #{identity.inspect}"

      identity
    end

    # Creates a new user account in OpenNebula, sets basic meta data and configures
    # the right group based on user's VO membership. This method is supposed to clean-up
    # after itself on failure, i.e. there will be no incomplete or inconsistent accounts
    # left in OpenNebula after an execution failure.
    #
    # @param identity [Hashie::Mash] processed user meta data
    # @param user_struct [Hashie::Mash] raw user meta data
    # @return [Hashie::Mash, NilClass] info about the new account or +nil+ on failure
    def create_account(identity, user_struct)
      user = Hashie::Mash.new
      user.is_new = true
      user.username = ::Digest::SHA1.hexdigest(identity.dn)

      Rails.logger.debug "[Hooks] [OneuserAutocreateHook] Creating account for " \
                         "#{identity.base_dn.inspect} in #{identity.vo.inspect}"
      one_user = ::OpenNebula::User.new(::OpenNebula::User.build_xml, client)
      rc = one_user.allocate(user.username, identity.dn, ::OpenNebula::User::X509_AUTH)
      check_retval(rc)

      begin
        one_group = get_group(identity.vo)
        fail "Group #{identity.vo.inspect} doesn't exists" if one_group.blank? || one_group['ID'].blank?

        rc = one_user.info
        check_retval(rc)

        rc = one_user.chgrp(one_group['ID'].to_i)
        check_retval(rc)

        # add custom metadata
        add_account_metadata(one_user, identity, user_struct)
      rescue => e
        Rails.logger.error "[Hooks] [OneuserAutocreateHook] #{e.message}! User " \
                           "could not be created automatically."
        one_user.delete

        return
      end

      user.group = one_group['NAME']
      user.id = one_user['ID']

      user
    end

    # Adds meta data to the newly created user account.
    #
    # @param one_user [OpenNebula::User]
    # @param identity [Hashie::Mash]
    # @param user_struct [Hashie::Mash]
    def add_account_metadata(one_user, identity, user_struct)
      template = []
      template << "X509_DN = #{identity.base_dn.inspect}"
      template << "ROCCI_AUTOCREATE = \"YES\""
      template << "VO = #{identity.vo.inspect}"
      template << "TIMESTAMP = #{DateTime.now.to_s.inspect}"
      template << "LOGIN_X509_DN = #{identity.dn.inspect}"
      template << "AUTH_STRATEGY = \"voms\""
      template << "ROCCI_SERVER = #{::ROCCIServer::VERSION.inspect}"

      rc = one_user.update(template.join("\n"), true)
      check_retval(rc)
    end

    # Gets an existing account from OpenNebula.
    #
    # @param username [String] name of the user
    # @return [Hashie::Mash] user account meta dat
    def get_account(username)
      user = Hashie::Mash.new
      user.is_new = false

      if @options.debug_mode
        one_user = user_pool.select { |user| user['NAME'] == username }.first

        if one_user
          user.id = one_user['ID']
          user.username = one_user['NAME']
          user.group = one_user['GNAME']
        end
      end

      user
    end

    # Gets an existing group from OpenNebula.
    #
    # @param groupname [String] name of the group
    # @return [OpenNebula::Group, NilClass] group instance or +nil+
    def get_group(groupname)
      group_pool.select { |group| group['NAME'] == groupname }.first
    end

    # Checks return codes for OpenNebula errors.
    #
    # @param rc [Object] error candidate
    # @return [TrueClass] not an error
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
