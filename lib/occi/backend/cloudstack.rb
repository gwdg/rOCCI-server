['rubygems',
 'uuidtools',
 'cloudstack_ruby_client',
 'occi/model',
 'occi/backend/manager'].each do |package|
  require package
end

module OCCI
  module Backend
    class CloudStack < OCCI::Core::Resource

      attr_reader :model

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

        kind.attributes.info!.rocci!.backend!.cloudstack!.scheme!.Default = 'http://my.occi.service/'
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

        @endpoint        = attributes.info.rocci.backend.cloudstack.endpoint
        @root_api_key    = attributes.info.rocci.backend.cloudstack.apikey
        @root_secret_key = attributes.info.rocci.backend.cloudstack.secretkey

        # TODO: Register files
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

      include OCCI::Backend::CloudStack::Compute

      def register_existing_resources(client)
        os_template_register(client)
        compute_offering_register(client)
        available_zone_register(client)
        compute_register_all_instances(client)
      end

      def os_template_register(client)
        # FIXME: Only implement the featured templates
        templates = client.list_templates 'templatefilter' => 'featured'

        templates['template'].each do |templ|
          related = %w|http://schemas.ogf.org/occi/infrastructure#os_tpl|
          # term    = templ['name'].downcase.chomp.gsub(/\W/, '_')
          term    = templ['id']
          scheme  = self.attributes.info.rocci.backend.cloudstack.scheme + "/occi/infrastructure/os_tpl#"
          title   = templ['name']
          attrs   = OCCI::Core::Attributes.new
          attrs.displaytext = templ['displaytext']
          attrs.ispublic    = templ['ispublic']
          attrs.format      = templ['format']
          mixin   = OCCI::Core::Mixin.new(scheme, term, title, attrs, related)
          @model.register mixin
          # File.open('/tmp/occi.tmp', 'a') { |file| file.write(templ.inspect) }
        end
      end

      def compute_offering_register(client)
        compute_offerings = client.list_service_offerings 'listall'  => 'true',
                                                          'issystem' => 'false'

        compute_offerings['serviceoffering'].each do |compute_offer|
          related = %w|http://schemas.ogf.org/occi/infrastructure#compute_offering|
          # term    = compute_offer['name'].downcase.chomp.gsub(/\W/, '_')
          term    = compute_offer['id']
          scheme  = self.attributes.info.rocci.backend.cloudstack.scheme + "/occi/infrastructure/compute_offering#"
          title   = compute_offer['name']

          attrs   = OCCI::Core::Attributes.new
          attrs.displaytext = compute_offer['displaytext'] if compute_offer['displaytext']   
          attrs.cpunumber   = compute_offer['cpunumber'] if compute_offer['cpunumber']
          attrs.cpuspeed    = compute_offer['cpuspeed'] if  compute_offer['cpuspeed']
          attrs.memory      = compute_offer['memory'] if  compute_offer['memory']
          attrs.offerha     = compute_offer['offerha'] if compute_offer['offerha']
          attrs.limitcpuuse = compute_offer['limitcpuuse'] if compute_offer['limitcpuuse']
          attrs.limitcpuuse = compute_offer['limitcpuuse'] if compute_offer['limitcpuuse']
          attrs.isvolatile  = compute_offer['isvolatile'] if compute_offer['isvolatile']
          attrs.issystem    = compute_offer['issystem'] if compute_offer['issystem']
          attrs.defaultuse  = compute_offer['defaultuse'] if compute_offer['defaultuse']

          mixin   = OCCI::Core::Mixin.new(scheme, term, title, attrs, related)
          @model.register mixin
        end
      end

      def available_zone_register(client)
        # FIXME: Fix the argument here
        available_zones = client.list_zones

        available_zones['zone'].each do |available_zone|
          related = %w|http://schemas.ogf.org/occi/infrastructure#available_zone|
          # term    = available_zone['name'].downcase.chomp.gsub(/\W/, '_')
          term    = available_zone['id']
          scheme  = self.attributes.info.rocci.backend.cloudstack.scheme + "/occi/infrastructure/available_zone#"
          title   = available_zone['name']

          attrs   = OCCI::Core::Attributes.new
          attrs.displaytext           = available_zone['displaytext'] if available_zone['displaytext']
          attrs.dns1                  = available_zone['dns1'] if available_zone['dns1']
          attrs.dns2                  = available_zone['dns2'] if available_zone['dns2']
          attrs.internaldns1          = available_zone['internaldns1'] if available_zone['internaldns1']
          attrs.internaldns2          = available_zone['internaldns2'] if available_zone['internaldns2']
          attrs.networktype           = available_zone['networktype'] if available_zone['networktype']
          attrs.securitygroupsenabled = available_zone['securitygroupsenabled'] if available_zone['securitygroupsenabled']
          attrs.zonetoken             = available_zone['zonetoken'] if available_zone['zonetoken']
          attrs.dhcpprovider          = available_zone['dhcpprovider'] if available_zone['dhcpprovider']
          attrs.localstorageenabled   = available_zone['localstorageenabled'] if available_zone['localstorageenabled']

          mixin   = OCCI::Core::Mixin.new(scheme, term, title, attrs, related)

          @model.register mixin
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
          :restart      => :compute_restart,
      }

      def query_async_result(client, jobid)
        result = nil
        if async
          OCCI::Log.debug("Async job id: #{jobid}")

          query_result = client.query_async_job_result 'jobid' => "#{jobid}"
          while query_result['jobstatus'] != 1
            query_result = client.query_async_job_result 'jobid' => "#{jobid}"
            raise OCCI::BackendError if query_result == 2
          end
          result = query_result['jobresult']
        end

        result
      end

      def check_result(result)
        raise OCCI::BackendError, "#{result}" if result.kind_of? Error
      end
    end
  end
end

