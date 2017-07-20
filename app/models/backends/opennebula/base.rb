module Backends
  module Opennebula
    class Base < ::Backends::Base
      API_VERSION = '3.0.0'.freeze

      # Translation table for known ONe errors
      ERROR_MAP = {
        ::OpenNebula::Error::EAUTHENTICATION => Errors::Backend::AuthenticationError,
        ::OpenNebula::Error::EAUTHORIZATION => Errors::Backend::AuthorizationError,
        ::OpenNebula::Error::ENO_EXISTS => Errors::Backend::EntityNotFoundError,
        ::OpenNebula::Error::EACTION => Errors::Backend::EntityStateError
      }.freeze

      # Connection errors
      ERROR_CONNECT = [
        XMLRPC::FaultException, Net::OpenTimeout, Net::ReadTimeout, Timeout::Error,
        Errno::ECONNRESET, Errno::ECONNABORTED, Errno::EPIPE, IOError, EOFError
      ].freeze

      protected

      # @see `Backends::Base`
      def post_initialize(args)
        @_client = ::OpenNebula::Client.new(
          client_secret(args), args.fetch(:endpoint),
          timeout: args.fetch(:timeout)
        )
      end

      # Accessor to internally stored client instance.
      #
      # @return [OpenNebula::Client] initialized OpenNebula client instance
      def raw_client
        @_client
      end

      # Returns an initialized instance of the requested pool.
      #
      # @example
      #    pool 'virtual_machine', :info_all # => #<OpenNebula::VirtualMachinePool>
      #
      # @param name [String] name of the pool, in `snake_case`
      # @param content [Symbol] one of `:info`, `:info_all`, `:info_mine`, `:info_group`
      # @return [OpenNebula::Pool] initialized pool instance
      def pool(name, content = :info)
        raise '`name` is a mandatory argument for pool construction' if name.blank?

        klass = "#{name}_pool".classify
        pool_instance = ::OpenNebula.const_get(klass).new(raw_client)
        client(Errors::Backend::InternalError) { pool_instance.send(content) }

        pool_instance
      end

      # Wrapper for calls to ONe's OCA.
      #
      # @example
      #    client(Errors::MyError) { vm_pool.info_all!  }
      #
      # @param e_klass [Class] error class to use for reporting failure
      # @return [Object] requested content, in case of success
      def client(e_klass)
        raise 'Block is a mandatory argument for client calls' unless block_given?

        retval = yield
        return retval unless ::OpenNebula.is_error?(retval)

        case retval.errno
        when *ERROR_MAP.keys
          raise ERROR_MAP[retval.errno], retval.message
        else
          raise e_klass, retval.message
        end
      rescue *ERROR_CONNECT => ex
        logger.fatal "Could not establish connection to OpenNebula: #{ex.message}"
        raise Errors::Backend::ConnectionError, 'Cloud platform is currently unavailable, connection failed'
      end

      # :nodoc:
      def client_secret(args)
        creds = args.fetch(:credentials)
        "#{creds.fetch(:user_id)}:#{creds.fetch(:secret_key)}"
      end
    end
  end
end
