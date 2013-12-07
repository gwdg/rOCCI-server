module Backends
  module Opennebula
    module Helpers

      module ComputeListHelper

        def compute_parse_backend_obj(backend_compute)
          compute = Occi::Infrastructure::Compute.new

          # include some basic mixins
          compute.mixins << 'http://opennebula.org/occi/infrastructure#compute'

          # include mixins stored in ON's VM template
          unless backend_compute['USER_TEMPLATE/OCCI_COMPUTE_MIXINS'].blank?
            backend_compute_mixins = JSON.parse(backend_compute['USER_TEMPLATE/OCCI_COMPUTE_MIXINS'])
            backend_compute_mixins.each do |mixin|
              compute.mixins << mixin unless mixin.blank?
            end
          end

          compute.id    = backend_compute['ID']
          compute.title = backend_compute['NAME'] if backend_compute['NAME']
          compute.summary = backend_compute['USER_TEMPLATE/DESCRIPTION'] if backend_compute['USER_TEMPLATE/DESCRIPTION']

          compute.cores = (backend_compute['TEMPLATE/VCPU'] || "1").to_i
          compute.memory = backend_compute['TEMPLATE/MEMORY'].to_f/1024 if backend_compute['TEMPLATE/MEMORY']

          compute.architecture = "x64" if backend_compute['TEMPLATE/OS/ARCH'] == "x86_64"
          compute.architecture = "x86" if backend_compute['TEMPLATE/OS/ARCH'] == "i686"

          compute.attributes['org.opennebula.compute.id'] = backend_compute['ID']
          compute.attributes['org.opennebula.compute.cpu'] = backend_compute['TEMPLATE/CPU'].to_f if backend_compute['TEMPLATE/CPU']
          compute.attributes['org.opennebula.compute.kernel'] = backend_compute['TEMPLATE/OS/KERNEL'] if backend_compute['TEMPLATE/OS/KERNEL']
          compute.attributes['org.opennebula.compute.initrd'] = backend_compute['TEMPLATE/OS/INITRD'] if backend_compute['TEMPLATE/OS/INITRD']
          compute.attributes['org.opennebula.compute.root'] = backend_compute['TEMPLATE/OS/ROOT'] if backend_compute['TEMPLATE/OS/ROOT']
          compute.attributes['org.opennebula.compute.kernel_cmd'] = backend_compute['TEMPLATE/OS/KERNEL_CMD'] if backend_compute['TEMPLATE/OS/KERNEL_CMD']
          compute.attributes['org.opennebula.compute.bootloader'] = backend_compute['TEMPLATE/OS/BOOTLOADER'] if backend_compute['TEMPLATE/OS/BOOTLOADER']
          compute.attributes['org.opennebula.compute.boot'] = backend_compute['TEMPLATE/OS/BOOT'] if backend_compute['TEMPLATE/OS/BOOT']

          result = compute_parse_set_state(backend_compute)
          compute.state = result.state
          result.actions.each { |a| compute.actions << a }

          result = compute_parse_links(backend_compute, compute)
          result.each { |link| compute.links << link }

          compute
        end

        def compute_parse_set_state(backend_compute)
          result = Hashie::Mash.new

          # In ON 4.4:
          #    VM_STATE=%w{INIT PENDING HOLD ACTIVE STOPPED SUSPENDED DONE FAILED
          #       POWEROFF UNDEPLOYED}
          #
          case backend_compute.state_str
          when "ACTIVE"
            result.state = "active"
            result.actions = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#stop http://schemas.ogf.org/occi/infrastructure/compute/action#restart http://schemas.ogf.org/occi/infrastructure/compute/action#suspend|
          when "FAILED"
            result.state = "failed"
            result.actions = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#restart|
          when "STOPPED", "SUSPENDED", "POWEROFF"
            result.state = "suspended"
            result.actions = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#start|
          when "PENDING"
            result.state = "waiting"
            result.actions = []
          else
            result.state = "inactive"
            result.actions = []
          end

          result
        end

        def compute_parse_links(backend_compute, compute)
          result = []

          result << compute_parse_links_storage(backend_compute, compute)
          result << compute_parse_links_network(backend_compute, compute)
          result.flatten!

          result
        end

        def compute_parse_links_storage(backend_compute, compute)
          result_storage_links = []

          backend_compute.each('TEMPLATE/DISK') do |disk|
            id = "compute_#{backend_compute['ID']}_disk_#{disk['DISK_ID']}"

            link = Occi::Infrastructure::Storagelink.new
            link.id = id
            link.state = "active"

            target = storage_get(disk['IMAGE_ID']) if disk['IMAGE_ID']
            unless target
              target = Occi::Infrastructure::Storage.new
              target.id = "#{STORAGE_GENERATED_PREFIX}#{id}"
              target.title = "Generated target for an on-the-fly created non-persistent disk"
            end

            link.target = target
            link.rel = target.kind
            link.title = target.title if target.title
            link.source = compute

            link.mixins << 'http://opennebula.org/occi/infrastructure#storagelink'

            unless backend_compute['USER_TEMPLATE/OCCI_STORAGELINK_MIXINS'].blank?
              backend_mixins = JSON.parse(backend_compute['USER_TEMPLATE/OCCI_STORAGELINK_MIXINS'])
              backend_mixins[id].each do |mixin|
                link.mixins << mixin unless mixin.blank?
              end if backend_mixins[id]
            end

            link.deviceid = "/dev/#{disk['TARGET']}" if disk['TARGET']
            link.attributes['org.opennebula.storagelink.bus'] = disk['BUS'] if disk['BUS']
            link.attributes['org.opennebula.storagelink.driver'] = disk['DRIVER'] if disk['TARGET']

            result_storage_links << link
          end

          result_storage_links
        end

        def compute_parse_links_network(backend_compute, compute)
          result_network_links = []

          backend_compute.each('TEMPLATE/NIC') do |nic|
            id = "compute_#{backend_compute['ID']}_nic_#{nic['NIC_ID']}"

            link = Occi::Infrastructure::Networkinterface.new
            link.id = id
            link.state = "active"

            target = network_get(nic['NETWORK_ID']) if nic['NETWORK_ID']
            unless target
              target = Occi::Infrastructure::Network.new
              target.id = "#{NETWORK_GENERATED_PREFIX}#{id}"
              target.title = "Generated target for a non-existent network (probably removed)"
            end

            link.target = target
            link.rel = target.kind
            link.title = target.title if target.title
            link.source = compute

            link.mixins << 'http://schemas.ogf.org/occi/infrastructure/networkinterface#ipnetworkinterface'
            link.mixins << 'http://opennebula.org/occi/infrastructure#networkinterface'

            unless backend_compute['USER_TEMPLATE/OCCI_NETWORKINTERFACE_MIXINS'].blank?
              backend_mixins = JSON.parse(backend_compute['USER_TEMPLATE/OCCI_NETWORKINTERFACE_MIXINS'])
              backend_mixins[id].each do |mixin|
                link.mixins << mixin unless mixin.blank?
              end if backend_mixins[id]
            end

            link.address = nic['IP'] if nic['IP']
            link.mac = nic['MAC'] if nic['MAC']
            link.interface = "eth#{nic['NIC_ID']}"
            link.model = nic['MODEL'] if nic['MODEL']

            link.attributes['org.opennebula.networkinterface.bridge'] = nic['BRIDGE'] if nic['BRIDGE']
            link.attributes['org.opennebula.networkinterface.white_ports_tcp'] = nic['WHITE_PORTS_TCP'] if nic['WHITE_PORTS_TCP']
            link.attributes['org.opennebula.networkinterface.black_ports_tcp'] = nic['BLACK_PORTS_TCP'] if nic['BLACK_PORTS_TCP']
            link.attributes['org.opennebula.networkinterface.white_ports_udp'] = nic['WHITE_PORTS_UDP'] if nic['WHITE_PORTS_UDP']
            link.attributes['org.opennebula.networkinterface.black_ports_udp'] = nic['BLACK_PORTS_UDP'] if nic['BLACK_PORTS_UDP']
            link.attributes['org.opennebula.networkinterface.icmp'] = nic['ICMP'] if nic['ICMP']

            result_network_links << link
          end

          result_network_links
        end

      end

    end
  end
end