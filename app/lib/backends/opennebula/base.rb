module Backends
  module Opennebula
    class Base < ::Backends::Base
      API_VERSION = '3.0.0'.freeze

      # Fallback cluster ID
      FALLBACK_CLUSTER_ID = '0'.freeze

      # Fallback connectivity value
      FALLBACK_CONNECTIVITY = 'public'.freeze

      # Translation table for known ONe errors
      ERROR_MAP = {
        ::OpenNebula::Error::EAUTHENTICATION => Errors::Backend::AuthenticationError,
        ::OpenNebula::Error::EAUTHORIZATION => Errors::Backend::AuthorizationError,
        ::OpenNebula::Error::ENO_EXISTS => Errors::Backend::EntityNotFoundError,
        ::OpenNebula::Error::EACTION => Errors::Backend::EntityActionError
      }.freeze

      # Connection errors
      ERROR_CONNECT = [
        XMLRPC::FaultException, Net::OpenTimeout, Net::ReadTimeout, Timeout::Error,
        Errno::ECONNRESET, Errno::ECONNABORTED, Errno::EPIPE, IOError, EOFError
      ].freeze

      # Flushes all internal caching structures. Data will be reloaded on demand.
      def flush_cache!
        @_pool_cache = {}
        @_active_context = nil
      end

      protected

      # @see `Backends::Base`
      def post_initialize(args)
        flush_cache!
        @_client = ::OpenNebula::Client.new(
          client_secret(args), args.fetch(:endpoint),
          timeout: args.fetch(:timeout)
        )
      end

      # Returns an initialized instance of the requested pool.
      #
      # @example
      #    pool :virtual_machine, :info_all # => #<OpenNebula::VirtualMachinePool>
      #
      # @param name [Symbol] name of the pool, in `snake_case`
      # @param content [Symbol] one of `:info`, `:info_all`, `:info_mine`, `:info_group`
      # @param reload [TrueClass, FalseClass] force reload of the pool
      # @return [OpenNebula::Pool] initialized pool instance
      def pool(name, content = :info, reload = false)
        unless name && content
          raise Errors::Backend::InternalError, '`name` and `content` are mandatory for pool construction'
        end
        pool_cache = @_pool_cache.fetch(name, {})
        return pool_cache[content] if !reload && pool_cache.key?(content)

        pool_cache[content] = klass_from("#{name}_pool").new(@_client)
        client(Errors::Backend::EntityRetrievalError) { pool_cache[content].send(content) }

        pool_cache[content]
      end

      # Returns an optionally initialized instance of a pool element.
      #
      # @example
      #    pool_element :virtual_machine, '1', :info # => #<OpenNebula::VirtualMachine>
      #
      # @param name [Symbol] name of the element, in `snake_case`
      # @param identifier [String] identifier of the desired element
      # @param content [Symbol, NilClass] `:info` or nothing
      # @return [OpenNebula::PoolElement] initialized pool element
      def pool_element(name, identifier, content = nil)
        unless name && identifier
          raise Errors::Backend::InternalError, '`name` and `identifier` are mandatory for pool element construction'
        end

        element = klass_from(name).new_with_id(identifier, @_client)
        client(Errors::Backend::EntityRetrievalError) { element.send(content) } if content
        element
      end

      # Allocates a pool element with a given template.
      #
      # @param name [Symbol] name of the element, in `snake_case`
      # @param template [String] element template
      # @param args [Array] arguments to pass as additional arguments to `allocate`
      # @return [OpenNebula::PoolElement] allocated element
      def pool_element_allocate(name, template, *args)
        unless name && template
          raise Errors::Backend::InternalError, '`name` and `template` are mandatory for pool element construction'
        end

        klass = klass_from(name)
        element = klass.new(klass.build_xml, @_client)

        client(Errors::Backend::EntityCreateError) { element.allocate(template, *args) }
        client(Errors::Backend::EntityRetrievalError) { element.info }

        element
      end

      # :nodoc:
      def klass_from(name)
        ::OpenNebula.const_get(name.to_s.classify)
      end

      # Wrapper for calls to ONe's OCA.
      #
      # @example
      #    client(Errors::MyError) { vm_pool.info_all!  }
      #
      # @param e_klass [Class] error class to use for reporting failure
      # @return [Object] requested content, in case of success
      def client(e_klass)
        raise Errors::Backend::InternalError, 'Block is a mandatory argument for client calls' unless block_given?
        if ERROR_CONNECT.include?(e_klass)
          raise Errors::Backend::InternalError, "Error #{e_klass} cannot be used with this wrapper"
        end

        retval = yield
        client_error!(retval, e_klass) if ::OpenNebula.is_error?(retval)

        retval
      rescue *ERROR_CONNECT => ex
        logger.fatal "Could not establish connection to OpenNebula: #{ex.message}"
        raise Errors::Backend::ConnectionError, 'Cloud platform is currently unavailable, connection failed'
      end

      # :nodoc:
      def client_error!(retval, e_klass)
        case retval.errno
        when *ERROR_MAP.keys
          raise ERROR_MAP[retval.errno], retval.message
        else
          raise e_klass, retval.message
        end
      end

      # :nodoc:
      def client_secret(args)
        creds = args.fetch(:credentials)
        "#{creds.fetch(:user_id)}:#{creds.fetch(:secret_key)}"
      end

      # :nodoc:
      def default_cluster
        active_group['TEMPLATE/DEFAULT_CLUSTER_ID'] || FALLBACK_CLUSTER_ID
      end

      # :nodoc:
      def default_connectivity
        active_group['TEMPLATE/DEFAULT_CONNECTIVITY'] || FALLBACK_CONNECTIVITY
      end

      # :nodoc:
      def default_network_phydev
        active_group['TEMPLATE/DEFAULT_NETWORK_PHYDEV'] \
          || raise(Errors::Backend::AuthorizationError, 'Not allowed to create user-defined networks')
      end

      # :nodoc:
      def active_context
        return @_active_context if @_active_context

        active_context = {
          user: pool(:user).detect { |u| u['NAME'] == credentials.fetch(:user_id) }
        }
        groups = pool(:group).to_a
        raise Errors::Backend::AuthorizationError, 'Only scoped access is allowed' if groups.many?
        active_context[:group] = groups.first

        @_active_context = active_context
      end

      # :nodoc:
      def active_user
        active_context[:user]
      end

      # :nodoc:
      def active_group
        active_context[:group]
      end

      # :nodoc:
      def active_identity
        active_user['TEMPLATE/IDENTITY'] || active_user['TEMPLATE/X509_DN'] || active_user['NAME']
      end
    end
  end
end
