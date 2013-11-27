['rubygems',
 'cloudstack_ruby_client',
 'occi/model',
 'occi/backend/manager'].each do |package|
  require package
end

module OCCI
  module Backend
    class CloudStack < OCCI::Core::Resource

      attr_reader :model,
                  :default_available_zone,
                  :default_compute_offering,
                  :default_os_template,
                  :default_disk_offering

      def self.kind_definition
        kind = OCCI::Core::Kind.new('http://rocci.info/server/backend#', 'cloudstack')

        kind.related = %w{http://rocci.org/serer#backend}
        kind.title   = "rOCCI CloudStack backend"
        kind.attributes.info!.rocci!.backend!.cloudstack!.admin!.Default     = "admin"
        kind.attributes.info!.rocci!.backend!.cloudstack!.admin!.Pattern     = '[a-zA-Z0-9_]*'
        kind.attributes.info!.rocci!.backend!.cloudstack!.admin!.Description = 'Username of CloudStack admin user'

        kind.attributes.info!.rocci!.backend!.cloudstack!.password!.Default     = 'password'
        kind.attributes.info!.rocci!.backend!.cloudstack!.password!.Description = "Password for CloudStack admin user"
        kind.attributes.info!.rocci!.backend!.cloudstack!.password!.Required    = true

        kind.attributes.info!.rocci!.backend!.cloudstack!.scheme!.Default = 'http://schemas.ogf.org'
        kind.attributes.info!.rocci!.backend!.cloudstack!.endpoint!.Default = 'http://localhost:8080/client'

        kind
      end

      def initialize(kind='http://rocci.org/server#backend', mixins=nil, attributes=nil, links=nil)
        scheme = attributes.info!.rocci!.backend!.clodustack!.scheme if attributes
        scheme ||= self.class.kind_definition.attributes.info.rocci.backend.cloudstack.scheme.Default
        scheme.chomp('/')

        @model = OCCI::Model.new
        @model.register_core
        @model.register_infrastructure
        @model.register_files('etc/backend/cloudstack/model', scheme)

        @endpoint        = attributes.info.rocci.backend.cloudstack.endpoint
        @root_api_key    = attributes.info.rocci.backend.cloudstack.apikey
        @root_secret_key = attributes.info.rocci.backend.cloudstack.secretkey

        OCCI::Backend::Manager.register_backend(OCCI::Backend::CloudStack, OCCI::Backend::CloudStack::OPERATIONS)

        OCCI::Log.debug("### Initializing connection with CloudStack")
        OCCI::Log.debug("CloudStack successful initialized")

        super(kind, mixins, attributes, links)
      end

      # Genereate a new CloudStack client, If the username is nil,
      # the client is generated for admin
      # username: _String_ Name of the User
      # [return] _Client_
      def client(username = nil)
        CloudstackRubyClient::Client.new @endpoint, @root_api_key, @root_secret_key
      end

      def new_client(username, password, email, first_name, last_name, domain, accout_type)
      
      end

      require 'occi/backend/cloudstack/compute'
      require 'occi/backend/cloudstack/storage'
      require 'occi/backend/cloudstack/network'

      include OCCI::Backend::CloudStack::Compute
      include OCCI::Backend::CloudStack::Storage
      include OCCI::Backend::CloudStack::Network

      def register_existing_resources(client)
        # mixins registering
        template_register(client)
        compute_offering_register(client)
        available_zone_register(client)
        disk_offering_register(client)

        # resources registering
        network_register_all_instances(client)
        storage_register_all_instances(client)
        compute_register_all_instances(client)
      end

      def template_register(client)
        # FIXME: Only implement the featured templates
        templates = client.list_templates 'templatefilter' => 'featured'

        if templates['template']
          templates['template'].each_with_index do |templ, idx|
            related = %w|http://schemas.ogf.org/occi/infrastructure#os_tpl|
            term    = templ['id']
            scheme  = self.attributes.info.rocci.backend.cloudstack.scheme + "/occi/infrastructure/os_tpl#"
            title   = templ['name']

            @default_os_template = "#{scheme+term}" if idx == 0

            attrs   = OCCI::Core::Attributes.new
            attrs.org!.apache!.cloudstack!.os_tpl!.displaytext!.Default     = templ['displaytext'] if templ['displaytext']
            attrs.org!.apache!.cloudstack!.os_tpl!.ispublic!.Default        = templ['ispublic'] if templ['ispublic']
            attrs.org!.apache!.cloudstack!.os_tpl!.ispublic!.Type           = "boolean"
            attrs.org!.apache!.cloudstack!.os_tpl!.isready!.Default         = templ['isready'] if templ['isready']
            attrs.org!.apache!.cloudstack!.os_tpl!.isready!.Type            = "boolean"
            attrs.org!.apache!.cloudstack!.os_tpl!.passwordenabled!.Default = templ['passwordenabled'] if templ['passwordenabled']
            attrs.org!.apache!.cloudstack!.os_tpl!.passwordenabled!.Type    = "boolean"
            attrs.org!.apache!.cloudstack!.os_tpl!.format!.Default          = templ['format'] if templ['format']
            attrs.org!.apache!.cloudstack!.os_tpl!.isfeatured!.Default      = templ['isfeatured'] if templ['isfeatured']
            attrs.org!.apache!.cloudstack!.os_tpl!.isfeatured!.Type         = "boolean"
            attrs.org!.apache!.cloudstack!.os_tpl!.crossZones!.Default      = templ['crossZones'] if templ['crossZones']
            attrs.org!.apache!.cloudstack!.os_tpl!.crossZones!.Type         = "boolean"
            attrs.org!.apache!.cloudstack!.os_tpl!.ostypeid!.Default        = templ['ostypeid'] if templ['ostypeid']
            attrs.org!.apache!.cloudstack!.os_tpl!.ostypename!.Default      = templ['ostypename'] if templ['ostypename']
            attrs.org!.apache!.cloudstack!.os_tpl!.account!.Default         = templ['account'] if templ['account']
            attrs.org!.apache!.cloudstack!.os_tpl!.zoneid!.Default          = templ['zoneid'] if templ['zoneid']
            attrs.org!.apache!.cloudstack!.os_tpl!.zonename!.Default        = templ['zonename'] if templ['zonename']
            attrs.org!.apache!.cloudstack!.os_tpl!.status!.Default          = templ['status'] if templ['status']
            attrs.org!.apache!.cloudstack!.os_tpl!.size!.Default            = templ['size'] if templ['size']
            attrs.org!.apache!.cloudstack!.os_tpl!.size!.Type               = "number"
            attrs.org!.apache!.cloudstack!.os_tpl!.templatetype!.Default    = templ['templatetype'] if templ['templatetype']
            attrs.org!.apache!.cloudstack!.os_tpl!.hypervisor!.Default      = templ['hypervisor'] if templ['hypervisor']
            attrs.org!.apache!.cloudstack!.os_tpl!.domain!.Default          = templ['domain'] if templ['domain']
            attrs.org!.apache!.cloudstack!.os_tpl!.domainid!.Default        = templ['domainid'] if templ['domainid']
            attrs.org!.apache!.cloudstack!.os_tpl!.isextractable!.Default   = templ['isextractable'] if templ['isextractable']
            attrs.org!.apache!.cloudstack!.os_tpl!.isextractable!.Type      = "boolean"
            attrs.org!.apache!.cloudstack!.os_tpl!.checksum!.Default        = templ['checksum'] if templ['checksum']
            attrs.org!.apache!.cloudstack!.os_tpl!.tags!.Default            = templ['tags'].to_s if templ['tags']
            attrs.org!.apache!.cloudstack!.os_tpl!.sshkeyenabled!.Default   = templ['sshkeyenabled'] if templ['sshkeyenabled']
            attrs.org!.apache!.cloudstack!.os_tpl!.sshkeyenabled!.Type      = "boolean"
            mixin   = OCCI::Core::Mixin.new(scheme, term, title, attrs, related)
            @model.register mixin
          end
        end
      end

      def compute_offering_register(client)
        compute_offerings = client.list_service_offerings 'listall'  => 'true',
                                                          'issystem' => 'false'

        if compute_offerings['serviceoffering']
          compute_offerings['serviceoffering'].each_with_index do |compute_offer, idx|
            related = %w|http://schemas.ogf.org/occi/infrastructure#resource_tpl|
            term    = compute_offer['id']
            scheme  = self.attributes.info.rocci.backend.cloudstack.scheme + "/occi/infrastructure/resource_tpl##"
            title   = compute_offer['name']

            @default_compute_offering = "#{scheme+term}" if idx == 0

            attrs   = OCCI::Core::Attributes.new
            attrs.org!.apache!.cloudstack!.resource_tpl!.displaytext!.Default = compute_offer['displaytext'] if compute_offer['displaytext']
            attrs.org!.apache!.cloudstack!.resource_tpl!.cpunumber!.Default   = compute_offer['cpunumber'] if compute_offer['cpunumber']
            attrs.org!.apache!.cloudstack!.resource_tpl!.cpunumber!.Type      = "number"
            attrs.org!.apache!.cloudstack!.resource_tpl!.cpuspeed!.Default    = compute_offer['cpuspeed'] if compute_offer['cpuspeed']
            attrs.org!.apache!.cloudstack!.resource_tpl!.cpuspeed!.Type       = "number"
            attrs.org!.apache!.cloudstack!.resource_tpl!.memory!.Default      = compute_offer['memory'] if compute_offer['memory']
            attrs.org!.apache!.cloudstack!.resource_tpl!.memory!.Type         = "number"
            attrs.org!.apache!.cloudstack!.resource_tpl!.storagetype!.Default = compute_offer['storagetype'] if compute_offer['storagetype']
            attrs.org!.apache!.cloudstack!.resource_tpl!.offerha!.Default     = compute_offer['offerha'] if compute_offer['offerha']
            attrs.org!.apache!.cloudstack!.resource_tpl!.offerha!.Type        = "boolean"
            attrs.org!.apache!.cloudstack!.resource_tpl!.limitcpuuse!.Default = compute_offer['limitcpuuse'] if compute_offer['limitcpuuse']
            attrs.org!.apache!.cloudstack!.resource_tpl!.limitcpuuse!.Type    = "boolean"
            attrs.org!.apache!.cloudstack!.resource_tpl!.issystem!.Default    = compute_offer['issystem'] if compute_offer['issystem']
            attrs.org!.apache!.cloudstack!.resource_tpl!.issystem!.Type       = "boolean"
            attrs.org!.apache!.cloudstack!.resource_tpl!.defaultuse!.Default  = compute_offer['defaultuse'] if compute_offer['defaultuse']
            attrs.org!.apache!.cloudstack!.resource_tpl!.defaultuse!.Type     = "boolean"
            mixin   = OCCI::Core::Mixin.new(scheme, term, title, attrs, related)
            @model.register mixin
          end
        end
      end

      def available_zone_register(client)
        available_zones = client.list_zones

        if available_zones['zone']
          available_zones['zone'].each_with_index do |available_zone, idx|
            related = %w|http://schemas.ogf.org/occi/infrastructure#available_zone|
            term    = available_zone['id']
            scheme  = self.attributes.info.rocci.backend.cloudstack.scheme + "/occi/infrastructure/available_zone#"
            title   = available_zone['name']
            
            @default_available_zone = "#{scheme+term}" if idx == 0
            attrs   = OCCI::Core::Attributes.new
            attrs.org!.apache!.cloudstack!.available_zone!.displaytext!.Default           = available_zone['displaytext'] if available_zone['displaytext']
            attrs.org!.apache!.cloudstack!.available_zone!.dns1!.Default                  = available_zone['dns1'] if available_zone['dns1']
            attrs.org!.apache!.cloudstack!.available_zone!.dns2!.Default                  = available_zone['dns2'] if available_zone['dns2']
            attrs.org!.apache!.cloudstack!.available_zone!.internaldns1!.Default          = available_zone['internaldns1'] if available_zone['internaldns1']
            attrs.org!.apache!.cloudstack!.available_zone!.internaldns2!.Default          = available_zone['internaldns2'] if available_zone['internaldns2']
            attrs.org!.apache!.cloudstack!.available_zone!.description!.Default           = available_zone['description'] if available_zone['description']
            attrs.org!.apache!.cloudstack!.available_zone!.dhcpprovider!.Default          = available_zone['dhcpprovider'] if available_zone['dhcpprovider']
            attrs.org!.apache!.cloudstack!.available_zone!.domain!.Default                = available_zone['domain'] if available_zone['domain']
            attrs.org!.apache!.cloudstack!.available_zone!.domainid!.Default              = available_zone['domainid'] if available_zone['domainid']
            attrs.org!.apache!.cloudstack!.available_zone!.domainname!.Default            = available_zone['domainname'] if available_zone['domainname']
            attrs.org!.apache!.cloudstack!.available_zone!.networktype!.Default           = available_zone['networktype'] if available_zone['networktype']
            attrs.org!.apache!.cloudstack!.available_zone!.zonetoken!.Default             = available_zone['zonetoken'] if available_zone['zonetoken']
            attrs.org!.apache!.cloudstack!.available_zone!.securitygroupsenabled!.Default = available_zone['securitygroupsenabled'] if available_zone['securitygroupsenabled']
            attrs.org!.apache!.cloudstack!.available_zone!.securitygroupsenabled!.Type    = "boolean"
            attrs.org!.apache!.cloudstack!.available_zone!.allocationstate!.Default       = available_zone['allocationstate'] if available_zone['allocationstate']
            attrs.org!.apache!.cloudstack!.available_zone!.localstorageenabled!.Type      = "boolean"

            mixin   = OCCI::Core::Mixin.new(scheme, term, title, attrs, related)
            @model.register mixin
          end
        end
      end

      def disk_offering_register(client)
        disk_offerings = client.list_disk_offerings 'listAll' => 'true'
        
        if disk_offerings['diskoffering']
          disk_offerings['diskoffering'].each_with_index do |disk_offer, idx|
            related = %w|http://schemas.ogf.org/occi/infrastructure#disk_offering|
            term    = disk_offer['id']
            scheme  = self.attributes.info.rocci.backend.cloudstack.scheme + "/occi/infrastructure/disk_offering#"
            title   = disk_offer['name']

            @default_disk_offering = "#{scheme+term}" if idx == 0

            attrs   = OCCI::Core::Attributes.new
            attrs.org!.apache!.cloudstack!.disk_offering!.displaytext!.Default  = disk_offer['displaytext'] if disk_offer['displaytext']
            attrs.org!.apache!.cloudstack!.disk_offering!.disksize!.Default     = disk_offer['disksize'] if disk_offer['size']
            attrs.org!.apache!.cloudstack!.disk_offering!.disksize!.Type        = "number"
            attrs.org!.apache!.cloudstack!.disk_offering!.storagetype!.Default  = disk_offer['storagetype'] if disk_offer['storagetype']
            attrs.org!.apache!.cloudstack!.disk_offering!.iscustomized!.Default = disk_offer['iscustomized'] if disk_offer['iscustomized']
            attrs.org!.apache!.cloudstack!.disk_offering!.iscustomized!.Type    = "boolean"

            mixin   = OCCI::Core::Mixin.new(scheme, term, title, attrs, related)
            @model.register mixin
          end
        end
      end

      OPERATIONS = { } 

      OPERATIONS["http://schemas.ogf.org/occi/infrastructure#compute"] = {

          # Generic resource operations
          :deploy       => :compute_deploy,
          :update_state => :compute_update_state,
          :delete       => :compute_delete,

          # Compute specific resource operations
          :start        => :compute_start,
          :stop         => :compute_stop,
          :restart      => :compute_restart
      }

      OPERATIONS["http://schemas.ogf.org/occi/infrastructure#storage"] = {

          # Generic resource operations
          :deploy       => :storage_deploy,
          :delete       => :storage_delete,

          # Storage specific resource operations
          :attach       => :storage_attach,
          :detach       => :storage_detach,
          :snapshot     => :storage_snapshot
      }

      OPERATIONS["http://schemas.ogf.org/occi/infrastructure#network"] = {
          # Generic resource operations
          :deploy       => :network_deploy,
          :update_state => :network_update_state,
          :delete       => :network_delete,

          # Network specific resource operations
          :up           => :network_up,
          :down         => :network_down,
          :restart      => :network_restart
      }

      def query_async_result(client, jobid)
        query_result = client.query_async_job_result 'jobid' => "#{jobid}"
        while query_result['jobstatus'] != 1
          raise OCCI::BackendError if query_result['jobstatus'] == 2
          OCCI::Log.debug("Async job id: #{jobid}")
          query_result = client.query_async_job_result 'jobid' => "#{jobid}"
          sleep 3 unless query_result['jobstatus'] == 1
        end
        query_result['jobresult']
      end

      def check_result(result)
        raise OCCI::BackendError, "#{result}" if result.kind_of? Error
      end
    end
  end
end

