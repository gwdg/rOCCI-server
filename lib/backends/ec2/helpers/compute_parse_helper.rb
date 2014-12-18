module Backends
  module Ec2
    module Helpers
      module ComputeParseHelper

        COMPUTE_FAKE_INTFS = ['eni-0', 'eni-1'].freeze

        def compute_parse_backend_obj(backend_compute, reservation_id)
          compute = Occi::Infrastructure::Compute.new

          if os_tpl_mixin = resource_tpl_get(resource_tpl_list_itype_to_term(backend_compute[:instance_type]))
            compute.mixins << os_tpl_mixin
            compute.attributes['occi.compute.cores'] = os_tpl_mixin.attributes.occi_.compute_.cores.default
            compute.attributes['occi.compute.memory'] = os_tpl_mixin.attributes.occi_.compute_.memory.default
          else
            compute.mixins << "http://schemas.ec2.aws.amazon.com/occi/infrastructure/resource_tpl##{resource_tpl_list_itype_to_term(backend_compute[:instance_type])}"
          end

          compute.mixins << "#{@options.backend_scheme}/occi/infrastructure/os_tpl##{os_tpl_list_image_to_term(backend_compute)}"
          compute.mixins << 'http://schemas.ec2.aws.amazon.com/occi/infrastructure/compute#aws_ec2_instance'

          compute.attributes['occi.core.id'] = backend_compute[:instance_id]
          compute.attributes['occi.compute.architecture'] = (backend_compute[:architecture] == 'x86_64') ? 'x64' : 'x86'

          compute.attributes['com.amazon.aws.ec2.reservation_id'] = reservation_id unless reservation_id.blank?
          compute.attributes['com.amazon.aws.ec2.availability_zone'] = backend_compute[:placement][:availability_zone] unless backend_compute[:placement].blank?
          compute.attributes['com.amazon.aws.ec2.state'] = backend_compute[:state][:name] unless backend_compute[:state].blank?
          compute.attributes['com.amazon.aws.ec2.hypervisor'] = backend_compute[:hypervisor] unless backend_compute[:hypervisor].blank?
          compute.attributes['com.amazon.aws.ec2.virtualization_type'] = backend_compute[:virtualization_type] unless backend_compute[:virtualization_type].blank?

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
            result.actions = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#stop http://schemas.ogf.org/occi/infrastructure/compute/action#restart|
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

            target = storage_get(blk[:ebs][:volume_id])
            next unless target # there is no way to render a link without a target

            link.target = target
            link.rel = target.kind
            link.title = target.title if target.title
            link.source = compute

            link.deviceid = blk[:device_name] if blk[:device_name]

            result_storage_links << link
          end

          result_storage_links.compact
        end

        def compute_parse_links_network(backend_compute, compute)
          intfs = backend_compute[:network_interfaces] || []
          result_network_links = []

          if intfs.empty?
            # public
            if backend_compute[:public_ip_address]
              intf = { network_interface_id: 'eni-0', association: {} }
              intf[:association][:public_ip] = backend_compute[:public_ip_address]
              intf[:private_ip_address] = nil
              result_network_links << compute_parse_link_networkinterface(compute, intf)
            end

            # private
            if backend_compute[:private_ip_address]
              intf = { network_interface_id: 'eni-1', association: {} }
              intf[:association][:public_ip] = nil
              intf[:private_ip_address] = backend_compute[:private_ip_address]
              result_network_links << compute_parse_link_networkinterface(compute, intf)
            end
          else
            intfs.each { |intf| result_network_links << compute_parse_link_networkinterface(compute, intf) }
          end

          result_network_links.compact
        end

        def compute_parse_link_networkinterface(compute, intf)
          id = "compute_#{compute.id}_nic_#{intf[:network_interface_id]}"

          link = Occi::Infrastructure::Networkinterface.new
          link.mixins << 'http://schemas.ogf.org/occi/infrastructure/networkinterface#ipnetworkinterface'

          link.id = id
          link.state = (compute.state == 'active') ? 'active' : 'inactive'

          target = intf[:vpc_id] ? network_get(intf[:vpc_id]) : Occi::Infrastructure::Network.new
          return unless target # there is no way to render a link without a target

          if intf[:association] && intf[:association][:public_ip]
            is_in_vpc = compute_parse_link_networkinterface_is_vpc_pub?(intf[:association][:public_ip])

            if intf[:vpc_id].blank? || is_in_vpc
              target.id = "public"
              target.title = 'Generated target for an interface based on a public EC2 network'
              link.id.gsub!("#{intf[:network_interface_id]}", 'eni-0') if is_in_vpc
            end

            link.address = intf[:association][:public_ip]
          else
            if intf[:vpc_id].blank?
              target.id = "private"
              target.title = 'Generated target for an interface based on a private EC2 network'
            end

            link.address = intf[:private_ip_address]
          end

          link.target = target
          link.rel = target.kind
          link.title = target.title if target.title
          link.source = compute

          link
        end

        private

        def compute_parse_link_networkinterface_is_vpc_pub?(intf_address)
          return if intf_address.blank?

          filters = []
          filters << { name: 'public-ip', values: [intf_address] }

          addresses = nil
          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            addresses = @ec2_client.describe_addresses(filters: filters).addresses
          end

          addresses.count > 0
        end

      end
    end
  end
end
