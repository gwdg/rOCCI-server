module Backends
  module Ec2
    module Helpers
      module ComputeParseHelper

        def compute_parse_backend_obj(backend_compute)
          compute = Occi::Infrastructure::Compute.new

          compute.attributes['occi.core.id'] = backend_compute[:instance_id]
          compute.mixins << "#{@options.backend_scheme}/occi/infrastructure/os_tpl##{os_tpl_list_image_to_term(backend_compute)}"
          compute.mixins << "http://schemas.ec2.aws.amazon.com/occi/infrastructure/resource_tpl##{resource_tpl_list_itype_to_term(backend_compute[:instance_type])}"

          # include state information and available actions
          result = compute_parse_state(backend_compute)
          compute.state = result.state
          result.actions.each { |a| compute.actions << a }

          # include storage and network links
          result = compute_parse_links(backend_compute, compute)
          result.each { |link| compute.links << link }

          compute
        end

        private

        def compute_parse_state(backend_compute)
          result = Hashie::Mash.new

          # In EC2:
          #   0 : pending
          #   16 : running
          #   32 : shutting-down
          #   48 : terminated
          #   64 : stopping
          #   80 : stopped
          case backend_compute[:state][:code].to_i
          when 16
            result.state = 'active'
            result.actions = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#stop http://schemas.ogf.org/occi/infrastructure/compute/action#restart http://schemas.ogf.org/occi/infrastructure/compute/action#suspend|
          when 80
            result.state = 'suspended'
            result.actions = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#start|
          when 0, 64
            result.state = 'waiting'
            result.actions = []
          else
            result.state = 'inactive'
            result.actions = []
          end

          result
        end

        def compute_parse_links(backend_compute, compute)
          result = []

          result << compute_parse_links_storage(backend_compute, compute)
          result << compute_parse_links_network(backend_compute, compute)
          result.flatten!

          result.compact
        end

        def compute_parse_links_storage(backend_compute, compute)
          blks = backend_compute[:block_device_mappings] || []
          result_storage_links = []

          blks.each do |blk|
            id = "compute_#{backend_compute[:instance_id]}_disk_#{blk[:ebs][:volume_id]}"

            link = Occi::Infrastructure::Storagelink.new
            link.id = id
            link.state = (compute.state == 'active') ? 'active' : 'inactive'

            target = Occi::Infrastructure::Storage.new
            target.id = blk[:ebs][:volume_id]
            target.title = 'EBS block device'

            link.target = target
            link.rel = target.kind
            link.title = target.title if target.title
            link.source = compute

            link.deviceid = blk[:device_name] if blk[:device_name]

            result_storage_links << link
          end

          result_storage_links
        end

        def compute_parse_links_network(backend_compute, compute)
          intfs = backend_compute[:network_interfaces] || []
          result_network_links = []

          if intfs.empty?
            # public
            if backend_compute[:public_ip_address]
              intf = { network_interface_id: 0, association: {} }
              intf[:association][:public_ip] = backend_compute[:public_ip_address]
              intf[:private_ip_address] = nil
              result_network_links << compute_parse_link_networkinterface(compute, intf)
            end

            # private
            if backend_compute[:private_ip_address]
              intf = { network_interface_id: 1, association: {} }
              intf[:association][:public_ip] = nil
              intf[:private_ip_address] = backend_compute[:private_ip_address]
              result_network_links << compute_parse_link_networkinterface(compute, intf)
            end
          else
            intfs.each { |intf| result_network_links << compute_parse_link_networkinterface(compute, intf) }
          end

          result_network_links
        end

        def compute_parse_link_networkinterface(compute, intf)
          id = "compute_#{compute.id}_nic_#{intf[:network_interface_id]}"

          link = Occi::Infrastructure::Networkinterface.new
          link.mixins << 'http://schemas.ogf.org/occi/infrastructure/networkinterface#ipnetworkinterface'

          link.id = id
          link.state = (compute.state == 'active') ? 'active' : 'inactive'

          target = Occi::Infrastructure::Network.new

          if intf[:association][:public_ip]
            target.id = "public"
            target.title = 'Generated target for an interface based on a public EC2 network'

            link.address = intf[:association][:public_ip]
          else
            target.id = "private"
            target.title = 'Generated target for an interface based on a private EC2 network'

            link.address = intf[:private_ip_address]
          end

          link.target = target
          link.rel = target.kind
          link.title = target.title if target.title
          link.source = compute

          link
        end

      end
    end
  end
end
