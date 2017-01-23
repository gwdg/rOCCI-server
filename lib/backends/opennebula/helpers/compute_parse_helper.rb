module Backends
  module Opennebula
    module Helpers
      module ComputeParseHelper
        STORAGE_GENERATED_PREFIX = 'generated_'
        NETWORK_GENERATED_PREFIX = 'generated_'
        CONTEXTUALIZATION_MIXIN_KEY = 'http://schemas.openstack.org/instance/credentials#public_key'
        CONTEXTUALIZATION_MIXIN_UD = 'http://schemas.openstack.org/compute/instance#user_data'
        CONTEXTUALIZATION_ATTR_KEY = 'org.openstack.credentials.publickey.data'
        CONTEXTUALIZATION_ATTR_UD = 'org.openstack.compute.user_data'

        def parse_backend_obj(backend_compute)
          compute = ::Occi::Infrastructure::Compute.new

          # include mixins stored in ON's VM template
          unless backend_compute['USER_TEMPLATE/OCCI_COMPUTE_MIXINS'].blank?
            backend_compute_mixins = backend_compute['USER_TEMPLATE/OCCI_COMPUTE_MIXINS'].split(' ')
            backend_compute_mixins.each do |mixin|
              compute.mixins << mixin unless mixin.blank?
            end
          end

          if backend_compute['TEMPLATE/CONTEXT']
            if backend_compute['TEMPLATE/CONTEXT/SSH_PUBLIC_KEY'] || backend_compute['TEMPLATE/CONTEXT/SSH_KEY']
              compute.mixins << CONTEXTUALIZATION_MIXIN_KEY
            end

            if backend_compute['TEMPLATE/CONTEXT/USER_DATA']
              compute.mixins << CONTEXTUALIZATION_MIXIN_UD
            end
          end

          # include basic OCCI attributes
          basic_attrs = parse_basic_attrs(backend_compute)
          compute.attributes.merge! basic_attrs

          # include contextualization attributes
          context_attrs = parse_context_attrs(backend_compute)
          compute.attributes.merge! context_attrs

          # include state information and available actions
          result = parse_state(backend_compute)
          compute.state = result.state
          result.actions.each { |a| compute.actions << a }

          # include storage and network links
          result = parse_links(backend_compute, compute)
          result.each { |link| compute.links << link }

          compute
        end

        def parse_basic_attrs(backend_compute)
          compute_attrs = ::Occi::Core::Attributes.new

          compute_attrs['occi.core.id']    = backend_compute['ID']
          compute_attrs['occi.core.title'] = backend_compute['NAME']
          compute_attrs['occi.core.summary'] = backend_compute['USER_TEMPLATE/DESCRIPTION'] unless backend_compute['USER_TEMPLATE/DESCRIPTION'].blank?

          compute_attrs['occi.compute.cores'] = (backend_compute['TEMPLATE/VCPU'] || 1).to_i
          compute_attrs['occi.compute.memory'] = (backend_compute['TEMPLATE/MEMORY'].to_f / 1024)
          # TODO: speed should contain a CPU speed (i.e. frequency in GHz)
          # compute_attrs['occi.compute.speed'] = ((backend_compute['TEMPLATE/CPU'] || 1).to_f / compute_attrs['occi.compute.cores'])

          compute_attrs['occi.compute.architecture'] = 'x64' if backend_compute['TEMPLATE/OS/ARCH'] == 'x86_64'
          compute_attrs['occi.compute.architecture'] = 'x86' if backend_compute['TEMPLATE/OS/ARCH'] == 'i686'

          compute_attrs
        end

        def parse_context_attrs(backend_compute)
          context_attrs = ::Occi::Core::Attributes.new

          if backend_compute['TEMPLATE/CONTEXT']
            context_attrs[CONTEXTUALIZATION_ATTR_KEY] = backend_compute['TEMPLATE/CONTEXT/SSH_PUBLIC_KEY'] || backend_compute['TEMPLATE/CONTEXT/SSH_KEY']

            # re-encode cloud-init configuration files as Base64
            context_attrs[CONTEXTUALIZATION_ATTR_UD] =
              if backend_compute['TEMPLATE/CONTEXT/USER_DATA'] && backend_compute['TEMPLATE/CONTEXT/USER_DATA'].match(/^\s*#cloud-config\s*$/)
                Base64.strict_encode64(backend_compute['TEMPLATE/CONTEXT/USER_DATA'])
              else
                backend_compute['TEMPLATE/CONTEXT/USER_DATA']
              end
          end

          context_attrs
        end

        def parse_state(backend_compute)
          result = Hashie::Mash.new

          # In ON 4.4:
          #    VM_STATE=%w{INIT PENDING HOLD ACTIVE STOPPED SUSPENDED DONE FAILED
          #       POWEROFF UNDEPLOYED}
          #
          #    LCM_STATE=%w{LCM_INIT PROLOG BOOT RUNNING MIGRATE SAVE_STOP SAVE_SUSPEND
          #        SAVE_MIGRATE PROLOG_MIGRATE PROLOG_RESUME EPILOG_STOP EPILOG
          #        SHUTDOWN CANCEL FAILURE CLEANUP_RESUBMIT UNKNOWN HOTPLUG SHUTDOWN_POWEROFF
          #        BOOT_UNKNOWN BOOT_POWEROFF BOOT_SUSPENDED BOOT_STOPPED CLEANUP_DELETE
          #        HOTPLUG_SNAPSHOT HOTPLUG_NIC HOTPLUG_SAVEAS HOTPLUG_SAVEAS_POWEROFF
          #        HOTPLUG_SAVEAS_SUSPENDED SHUTDOWN_UNDEPLOY EPILOG_UNDEPLOY
          #        PROLOG_UNDEPLOY BOOT_UNDEPLOY}
          #
          case backend_compute.state_str
          when 'ACTIVE'
            # ACTIVE is a very broad term, look at lcm_state_str too
            if backend_compute.lcm_state_str == 'RUNNING'
              result.state = 'active'
              result.actions = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#stop http://schemas.ogf.org/occi/infrastructure/compute/action#restart http://schemas.ogf.org/occi/infrastructure/compute/action#suspend|
            else
              result.state = 'inactive'
              result.actions = []
            end
          when 'FAILED'
            result.state = 'error'
            result.actions = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#restart|
          when 'STOPPED', 'SUSPENDED', 'POWEROFF'
            result.state = 'suspended'
            result.actions = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#start|
          when 'PENDING'
            result.state = 'waiting'
            result.actions = []
          else
            result.state = 'inactive'
            result.actions = []
          end

          result
        end

        def parse_links(backend_compute, compute)
          result = []

          result << parse_links_storage(backend_compute, compute)
          result << parse_links_network(backend_compute, compute)
          result.flatten!

          result
        end

        def parse_links_storage(backend_compute, compute)
          result_storage_links = []

          backend_compute.each('TEMPLATE/DISK') do |disk|
            id = "compute_#{backend_compute['ID']}_disk_#{disk['DISK_ID']}"

            link = ::Occi::Infrastructure::Storagelink.new
            link.id = id
            link.state = (compute.state == 'active') ? 'active' : 'inactive'

            if disk['IMAGE_ID']
              begin
                target = @other_backends['storage'].get(disk['IMAGE_ID'])
              rescue Backends::Errors::UserNotAuthorizedError
                # image exists but isn't available for this user
                target = ::Occi::Infrastructure::Storage.new
                target.id = "#{STORAGE_GENERATED_PREFIX}#{id}"
                target.title = 'Generated target for a disk based on an outdated and unpublished image'
              rescue Backends::Errors::ResourceNotFoundError
                # image doesn't exist anymore or it's a read-only appliance OS image
                target = ::Occi::Infrastructure::Storage.new
                target.id = "#{STORAGE_GENERATED_PREFIX}#{id}"
                target.title = 'Generated target for an OS disk or a removed image'
              end
            else
              target = ::Occi::Infrastructure::Storage.new
              target.id = "#{STORAGE_GENERATED_PREFIX}#{id}"
              target.title = 'Generated target for an on-the-fly created non-persistent disk'
            end

            link.target = target
            link.rel = target.kind
            link.title = target.title if target.title
            link.source = compute

            unless backend_compute["USER_TEMPLATE/OCCI_STORAGELINK_MIXINS/DISK_#{disk['DISK_ID']}"].blank?
              backend_mixins = backend_compute["USER_TEMPLATE/OCCI_STORAGELINK_MIXINS/DISK_#{disk['DISK_ID']}"].split(' ')
              backend_mixins.each do |mixin|
                link.mixins << mixin unless mixin.blank?
              end
            end

            link.deviceid = "/dev/#{disk['TARGET']}" if disk['TARGET']

            result_storage_links << link
          end

          result_storage_links
        end

        def parse_links_network(backend_compute, compute)
          result_network_links = []

          backend_compute.each('TEMPLATE/NIC') do |nic|
            id = "compute_#{backend_compute['ID']}_nic_#{nic['NIC_ID']}"

            link = ::Occi::Infrastructure::Networkinterface.new
            link.id = id
            link.state = (compute.state == 'active') ? 'active' : 'inactive'

            if nic['NETWORK_ID']
              begin
                target = @other_backends['network'].get(nic['NETWORK_ID'])
              rescue Backends::Errors::UserNotAuthorizedError
                # network exists but isn't available for this user
                target = ::Occi::Infrastructure::Network.new
                target.id = "#{NETWORK_GENERATED_PREFIX}#{id}"
                target.title = 'Generated target for an interface based on an outdated and unpublished network'
              rescue Backends::Errors::ResourceNotFoundError
                # network doesn't exist anymore
                target = ::Occi::Infrastructure::Network.new
                target.id = "#{NETWORK_GENERATED_PREFIX}#{id}"
                target.title = 'Generated target for an interface based on a removed network'
              end
            else
              target = ::Occi::Infrastructure::Network.new
              target.id = "#{NETWORK_GENERATED_PREFIX}#{id}"
              target.title = 'Generated target for an interface based on a non-existent network'
            end

            link.target = target
            link.rel = target.kind
            link.title = target.title if target.title
            link.source = compute

            link.mixins << 'http://schemas.ogf.org/occi/infrastructure/networkinterface#ipnetworkinterface'

            unless backend_compute["USER_TEMPLATE/OCCI_NETWORKINTERFACE_MIXINS/NIC_#{nic['NIC_ID']}"].blank?
              backend_mixins = backend_compute["USER_TEMPLATE/OCCI_NETWORKINTERFACE_MIXINS/NIC_#{nic['NIC_ID']}"].split(' ')
              backend_mixins.each do |mixin|
                link.mixins << mixin unless mixin.blank?
              end
            end

            link.address = nic['IP'] if nic['IP']
            link.mac = nic['MAC'] if nic['MAC']
            link.interface = "eth#{nic['NIC_ID']}"

            result_network_links << link
          end

          result_network_links
        end
      end
    end
  end
end
