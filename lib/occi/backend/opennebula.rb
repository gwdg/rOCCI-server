require 'rubygems'
require 'uuidtools'
require 'oca'
require 'occi/model'

require 'occi/backend/opennebula/auth/server_cipher_auth'

require 'occi/backend/manager'

# OpenNebula backend based mixins
#require 'occi/extensions/one/Image'
#require 'occi/extensions/one/Network'
#require 'occi/extensions/one/VirtualMachine'
#require 'occi/extensions/one/VNC'

#require 'occi/extensions/Reservation'

require 'occi/log'

require 'openssl'

include OpenNebula

module OCCI
  module Backend
    class OpenNebula < OCCI::Core::Resource

      # Default interval for timestamps. Tokens will be generated using the same
      # timestamp for this interval of time.
      # THIS VALUE CANNOT BE LOWER THAN EXPIRE_MARGIN
      EXPIRE_DELTA  = 1800

      # Tokens will be generated if time > EXPIRE_TIME - EXPIRE_MARGIN
      EXPIRE_MARGIN = 300

      attr_reader :model

      def self.kind_definition
        kind = OCCI::Core::Kind.new('http://rocci.info/server/backend#', 'opennebula')

        kind.related = %w{http://rocci.org/serer#backend}
        kind.title   = "rOCCI OpenNebula backend"

        kind.attributes.info!.rocci!.backend!.opennebula!.admin!.Default     = 'oneadmin'
        kind.attributes.info!.rocci!.backend!.opennebula!.admin!.Pattern     = '[a-zA-Z0-9_]*'
        kind.attributes.info!.rocci!.backend!.opennebula!.admin!.Description = 'Username of OpenNebula admin user'

        kind.attributes.info!.rocci!.backend!.opennebula!.password!.Description = 'Password for OpenNebula admin user'
        kind.attributes.info!.rocci!.backend!.opennebula!.password!.Required    = true

        kind.attributes.info!.rocci!.backend!.opennebula!.endpoint!.Default = 'http://localhost:2633/RPC2'

        kind.attributes.info!.rocci!.backend!.opennebula!.scheme!.Default = 'http://my.occi.service/'

        kind
      end

      def initialize(kind='http://rocci.org/server#backend', mixins=nil, attributes=nil, links=nil)
        scheme = attributes.info!.rocci!.backend!.opennebula!.scheme if attributes
        scheme ||= self.class.kind_definition.attributes.info.rocci.backend.opennebula.scheme.Default
        scheme.chomp('/')
        @model = OCCI::Model.new
        @model.register_core
        @model.register_infrastructure
        @model.register_files('etc/backend/opennebula/model', scheme)
        @model.register_files('etc/backend/opennebula/templates', scheme)
        OCCI::Backend::Manager.register_backend(OCCI::Backend::OpenNebula, OCCI::Backend::OpenNebula::OPERATIONS)

        admin    = attributes.info.rocci.backend.opennebula.admin
        password = attributes.info.rocci.backend.opennebula.password

        @server_auth           = OpenNebula::Auth::ServerCipherAuth.new(admin, password)
        @token_expiration_time = Time.now.to_i + 1800
        @endpoint              = attributes.info.rocci.backend.opennebula.endpoint
        @lock                  = Mutex.new

        # TODO: create mixins from existing templates

        # initialize OpenNebula connection
        OCCI::Log.debug("### Initializing connection with OpenNebula")

        # TODO: check for error!
        #       @one_client = Client.new(OCCI::Server.config['one_user'] + ':' + OCCI::Server.config['one_password'], OCCI::Server.config['one_xmlrpc'])
        # @one_client = OpenNebula::Client.new(admin + ':' + password, endpoint)

        puts "OpenNebula successful initialized"
        super(kind, mixins, attributes, links)
      end

      def authorized?(username, password)
        one_pass = get_password(username, 'core|public')
        one_user = get_username(Digest::SHA1.hexdigest(password))
        return true if (one_pass == Digest::SHA1.hexdigest(password) && one_user == username)
        false
      end

      # Gets the password associated with a username
      # username:: _String_ the username
      # driver:: _String_ list of valid drivers for the user, | separated
      # [return] _Hash_ with the username
      def get_password(username, driver=nil)
        user_pool = OpenNebula::UserPool.new(client)
        rc        = user_pool.info
        raise rc.message if check_rc(rc)

        xpath = "USER[NAME=\"#{username}\""
        if driver
          xpath << " and (AUTH_DRIVER=\""
          xpath << driver.split('|').join("\" or AUTH_DRIVER=\"") << '")'
        end
        xpath << "]/PASSWORD"

        user_pool[xpath]
      end

      # Gets the username associated with a password
      # password:: _String_ the password
      # [return] _Hash_ with the username
      def get_username(password)
        user_pool = OpenNebula::UserPool.new(client)
        rc        = user_pool.info
        raise rc.message if check_rc(rc)

        xpath = "USER[PASSWORD=\"#{password.to_s.delete("\s")}\"]/NAME"
        user_pool[xpath]
      end

      # Generate a new OpenNebula client for the target User, if the username
      # is nil the Client is generated for the server_admin
      # ussername:: _String_ Name of the User
      # [return] _Client_
      def client(username=nil)
        expiration_time = @lock.synchronize {
          time_now = Time.now.to_i

          if time_now > @token_expiration_time - EXPIRE_MARGIN
            @token_expiration_time = time_now + EXPIRE_DELTA
          end

          @token_expiration_time
        }

        token = @server_auth.login_token(expiration_time, username)

        OpenNebula::Client.new(token, @endpoint)
      end

      # The ACL level to be used when querying resource in OpenNebula:
      # - INFO_ALL returns all resources and works only when running under the oneadmin account
      # - INFO_GROUP returns the resources of the account + his group (= default)
      # - INFO_MINE returns only the resources of the account
      INFO_ACL = OpenNebula::Pool::INFO_GROUP

      # OpenNebula backend
      require 'occi/backend/opennebula/compute'
      require 'occi/backend/opennebula/network'
      require 'occi/backend/opennebula/storage'

      include OCCI::Backend::OpenNebula::Compute
      include OCCI::Backend::OpenNebula::Network
      include OCCI::Backend::OpenNebula::Storage


      # Operation mappings

      OPERATIONS = { }

      OPERATIONS["http://schemas.ogf.org/occi/infrastructure#compute"] = {

          # Generic resource operations
          :deploy       => :compute_deploy,
          :update_state => :compute_update_state,
          :delete       => :compute_delete,

          # Compute specific resource operations
          :start        => :compute_start,
          :stop         => :compute_stop,
          :restart      => :compute_restart,
          :suspend      => :compute_suspend
      }

      OPERATIONS["http://schemas.ogf.org/occi/infrastructure#network"] = {

          # Generic resource operations
          :deploy       => :network_deploy,
          :update_state => :network_update_state,
          :delete       => :network_delete,

          # Network specific resource operations
          :up           => :network_up,
          :down         => :network_down
      }

      OPERATIONS["http://schemas.ogf.org/occi/infrastructure#storage"] = {

          # Generic resource operations
          :deploy       => :storage_deploy,
          :update_state => :storage_update_state,
          :delete       => :storage_delete,

          # Network specific resource operations
          :online       => :storage_online,
          :offline      => :storage_offline,
          :backup       => :storage_backup,
          :snapshot     => :storage_snapshot,
          :resize       => :storage_resize
      }

      # ---------------------------------------------------------------------------------------------------------------------
      #        private
      # ---------------------------------------------------------------------------------------------------------------------

      # ---------------------------------------------------------------------------------------------------------------------
      def check_rc(rc)
        if rc.class == Error
          raise OCCI::BackendError, "Error message from OpenNebula: #{rc.to_str}"
          # TODO: return failed!
        end
      end

      # ---------------------------------------------------------------------------------------------------------------------
      # Generate a new occi id for resources created directly in OpenNebula using a seed id and the kind identifier
      def generate_occi_id(kind, seed_id)
        # Use strings as kind ids
        kind = kind.type_identifier if kind.kind_of?(OCCI::Core::Kind)
        return UUIDTools::UUID.sha1_create(UUIDTools::UUID_DNS_NAMESPACE, "#{kind}:#{seed_id}").to_s
      end

      # ---------------------------------------------------------------------------------------------------------------------
      public
      # ---------------------------------------------------------------------------------------------------------------------


      # ---------------------------------------------------------------------------------------------------------------------
      def register_existing_resources(client)
        # get all compute objects
        resource_template_register(client)
        os_template_register(client)
        compute_register_all_instances(client)
        network_register_all_instances(client)
        storage_register_all_instances(client)
      end

      # ---------------------------------------------------------------------------------------------------------------------
      def resource_template_register(client)
        # currently not directly supported by OpenNebula
      end

      # ---------------------------------------------------------------------------------------------------------------------
      def os_template_register(client)
        backend_object_pool=TemplatePool.new(client)
        backend_object_pool.info_all
        backend_object_pool.each do |backend_object|
          related = %w|http://schemas.ogf.org/occi/infrastructure#os_tpl|
          term    = backend_object['NAME'].downcase.chomp.gsub(/\W/, '_')
          # TODO: implement correct schema for service provider
          scheme  = self.attributes.info.rocci.backend.opennebula.scheme + "/occi/infrastructure/os_tpl#"
          title   = backend_object['NAME']
          mixin   = OCCI::Core::Mixin.new(scheme, term, title, nil, related)
          @model.register(mixin)
        end
      end

    end
  end
end
