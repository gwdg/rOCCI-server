require 'timeout'
require 'securerandom'

module Backends
  module Opennebula
    class Base
      API_VERSION = '2.0.0'.freeze
      TPL_TERM_PREFIX = 'uuid'.freeze
      AVAIL_ZONE_MIXIN = 'http://fedcloud.egi.eu/occi/infrastructure#availability_zone'.freeze
      DN_BASED_AUTHS = %w(x509 voms).freeze

      # load helpers for JSON -> Collection conversion
      include Backends::Helpers::JsonCollectionHelper

      def initialize(delegated_user, options, server_properties, logger, dalli_cache)
        @delegated_user = Hashie::Mash.new(delegated_user)
        @options = Hashie::Mash.new(options)
        @server_properties = Hashie::Mash.new(server_properties)
        @logger = logger || Rails.logger
        @dalli_cache = dalli_cache
        @other_backends = {}
        @client = nil

        # establish connection with OpenNebula
        @cloud_auth_client = init_connection(@delegated_user, @options)
        run_authn

        @options.backend_scheme ||= "http://occi.#{@server_properties.hostname || 'localhost'}"

        path = @options.fixtures_dir || ''
        read_resource_tpl_fixtures(path)
      end

      def add_other_backend(backend_type, backend_instance)
        fail 'Type and instance must be provided!' unless backend_type && backend_instance
        @other_backends[backend_type] = backend_instance
      end

      protected

      def tpl_to_term(tpl)
        fixed = tpl['NAME'].downcase.gsub(/[^0-9a-z]/i, '_')
        fixed = fixed.gsub(/_+/, '_').chomp('_').reverse.chomp('_').reverse
        "#{TPL_TERM_PREFIX}_#{fixed}_#{tpl['ID']}"
      end

      def term_to_id(term)
        matched = term.match(/^.+_(?<id>\d+)$/)

        fail Backends::Errors::IdentifierNotValidError,
             "Tpl term is invalid! #{term.inspect}" unless matched

        matched[:id].to_i
      end

      def cid_to_avail_zone(cid)
        cluster = ::OpenNebula::Cluster.new(
                    ::OpenNebula::Cluster.build_xml(cid),
                    @client
                  )
        rc = cluster.info
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        tpl_to_term(cluster)
      end

      def avail_zones_from_resource(resource)
        return [] if resource.blank?
        mxns = resource.mixins.to_a.select { |mxn| mxn.related_to? AVAIL_ZONE_MIXIN }
        mxns.collect { |mxn| term_to_id mxn.term }
      end

      private

      # load helpers for working with OCCI extensions
      include Backends::Helpers::ExtensionsHelper

      def read_resource_tpl_fixtures(base_path)
        path = File.join(base_path, 'resource_tpl', '*.json')
        @resource_tpl = ::Occi::Core::Mixins.new

        Dir.glob(path) do |json_file|
          @resource_tpl.merge read_from_json(json_file).mixins if File.readable?(json_file)
        end
      end

      def init_connection(delegated_user, options)
        conf = ::Hashie::Mash.new
        conf.auth = delegated_user.auth_.type
        conf.one_xmlrpc = options.xmlrpc_endpoint

        conf.srv_auth = 'cipher'
        conf.srv_user = options.username
        conf.srv_passwd = options.password

        Backends::Opennebula::Authn::CloudAuthClient.new(conf)
      end

      def run_authn
        return if @client

        username = @cloud_auth_client.auth(@delegated_user.auth_.credentials)
        fail Backends::Errors::AuthenticationError,
             "User #{@delegated_user.identity.inspect} could not be authenticated!" if username.blank?

        @client = @cloud_auth_client.client(username)
        fail Backends::Errors::AuthenticationError,
             "Could not get a client for user #{@delegated_user.identity.inspect}!" unless @client
      end

      def check_retval(rc, e_klass)
        return true unless ::OpenNebula.is_error?(rc)

        case rc.errno
          when ::OpenNebula::Error::EAUTHENTICATION
            fail Backends::Errors::AuthenticationError, rc.message
          when ::OpenNebula::Error::EAUTHORIZATION
            fail Backends::Errors::UserNotAuthorizedError, rc.message
          when ::OpenNebula::Error::ENO_EXISTS
            fail Backends::Errors::ResourceNotFoundError, rc.message
          when ::OpenNebula::Error::EACTION
            fail Backends::Errors::ResourceStateError, rc.message
          else
            fail e_klass, rc.message
        end
      end
    end
  end
end
