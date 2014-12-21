module Backends
  module Ec2
    module Helpers
      module ComputeCreateHelper

        COMPUTE_BASE64_REGEXP = /^[A-Za-z0-9+\/]+={0,2}$/
        COMPUTE_USER_DATA_SIZE_LIMIT = 16384
        COMPUTE_DONT_WAIT_FOR_STATUSES = ['shutting-down', 'terminated', 'stopping', 'stopped'].freeze
        COMPUTE_DN_BASED_AUTHS = %w(x509 voms).freeze

        def compute_create_with_os_tpl(compute)
          @logger.debug "[Backends] [Ec2Backend] Deploying #{compute.inspect}"

          # generate and amend inst options
          instance_opts = compute_create_instance_opts(compute)
          instance_opts = compute_create_add_inline_ntwrkintfs_vpc(compute, instance_opts)
          tags = compute_create_instance_tags(compute, instance_opts)

          instance_id = nil
          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            ec2_response = @ec2_client.run_instances(instance_opts)
            instance_id = ec2_response.instances.first[:instance_id]

            @ec2_client.create_tags(
              resources: [instance_id],
              tags: tags
            )
          end

          # run post-inst actions
          compute_create_add_inline_strglnks(compute, instance_id)
          compute_create_add_inline_ntwrkintfs_elastic(compute, instance_id)

          instance_id
        end

        private

        def compute_create_user_data(compute)
          if compute.attributes.org!.openstack!.compute!.user_data
            fail Backends::Errors::ResourceNotValidError, "User data exceeds the allowed size of #{COMPUTE_USER_DATA_SIZE_LIMIT} bytes!" unless \
              compute.attributes['org.openstack.compute.user_data'].bytesize <= COMPUTE_USER_DATA_SIZE_LIMIT
          end

          if compute.attributes.org!.openstack!.compute!.user_data
            fail Backends::Errors::ResourceNotValidError, 'User data contains invalid characters!' unless \
              COMPUTE_BASE64_REGEXP.match(compute.attributes['org.openstack.compute.user_data'].gsub("\n", ''))
          end

          compute.attributes.org!.openstack!.compute!.user_data || ''
        end

        def compute_create_instance_opts(compute)
          os_tpl_mixins = compute.mixins.get_related_to(Occi::Infrastructure::OsTpl.mixin.type_identifier)
          os_tpl = os_tpl_mixins.first

          resource_tpl_mixins = compute.mixins.get_related_to(Occi::Infrastructure::ResourceTpl.mixin.type_identifier)
          resource_tpl = resource_tpl_mixins.first

          @logger.debug "[Backends] [Ec2Backend] Deploying with template #{os_tpl.term.inspect} in size #{resource_tpl.inspect}"
          os_tpl = os_tpl_list_term_to_image_id(os_tpl.term)
          resource_tpl = resource_tpl_list_term_to_itype(resource_tpl ? resource_tpl.term : 't1_micro')

          {
            image_id: os_tpl,
            instance_type: resource_tpl,
            min_count: 1, max_count: 1,
            user_data: compute_create_user_data(compute),
            monitoring: {
              enabled: false,
            },
            placement: {
              availability_zone: @options.aws_availability_zone,
            }
          }
        end

        def compute_create_add_inline_ntwrkintfs_vpc(compute, instance_opts)
          instance_opts ||= {}
          ntwrkintfs = compute.links.to_a.select { |link| link.kind.type_identifier == 'http://schemas.ogf.org/occi/infrastructure#networkinterface' }
          ntwrkintfs.reject! { |intf| intf.target.end_with?('/network/public') || intf.target.end_with?('/network/private') }

          if ntwrkintfs.any?
            fail Backends::Errors::ResourceNotValidError, 'Compute instance cannot be in more than 1 VPC network!' if ntwrkintfs.count > 1
            instance_opts[:subnet_id] = compute_create_get_first_vpc_subnet(ntwrkintfs.first.target.split('/').last)
          end

          instance_opts
        end

        def compute_create_add_inline_strglnks(compute, instance_id)
          strglnks = compute.links.to_a.select { |link| link.kind.type_identifier == 'http://schemas.ogf.org/occi/infrastructure#storagelink' }

          compute_create_wait4running(instance_id) if strglnks.any?
          strglnks.each do |storagelink|
            @logger.debug "[Backends] [Ec2Backend] Attaching inline storage #{storagelink.target.inspect} to \"/compute/#{instance_id}\""

            storagelink.source = "/compute/#{instance_id}"
            compute_attach_storage(storagelink)
          end
        end

        def compute_create_add_inline_ntwrkintfs_elastic(compute, instance_id)
          ntwrkintfs = compute.links.to_a.select { |link| link.kind.type_identifier == 'http://schemas.ogf.org/occi/infrastructure#networkinterface' }

          compute_create_wait4running(instance_id) if ntwrkintfs.any?
          ntwrkintfs.each do |networkinterface|
            next unless networkinterface.target.end_with?('/network/public')
            @logger.debug "[Backends] [Ec2Backend] Attaching inline network #{networkinterface.target.inspect} to \"/compute/#{instance_id}\""

            networkinterface.source = "/compute/#{instance_id}"
            compute_attach_network(networkinterface)
          end
        end

        def compute_create_instance_tags(compute, instance_opts)
          serialized_mixins = compute.mixins.to_a.map { |m| m.type_identifier }.join(' ')

          tags = []
          tags << { key: 'Name', value: (compute.title || "rOCCI-server instance #{instance_opts[:instance_type]} + #{instance_opts[:image_id]}") }
          tags << { key: 'ComputeMixins', value: serialized_mixins } if serialized_mixins.length < 255
          tags << { key: 'UserIdentity', value: @delegated_user.identity } if @delegated_user.identity.length < 255

          if COMPUTE_DN_BASED_AUTHS.include?(@delegated_user.auth_.type)
            tags << { key: 'UserX509DN', value: @delegated_user.identity } if @delegated_user.identity.length < 255
          end

          tags
        end

        def compute_create_get_first_vpc_subnet(vpc_id)
          fail Backends::Errors::ResourceNotValidError, 'Networkinterface is missing a valid target attribute!' if vpc_id.blank?

          filters = []
          filters << { name: 'vpc-id', values: [vpc_id] }

          subnets = nil
          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            subnets = @ec2_client.describe_subnets(filters: filters).subnets
            fail Backends::Errors::ResourceNotValidError, "VPC network #{vpc_id.inspect} has a non-standard " \
              "number of subnets [#{subnets.count}]!" unless subnets && subnets.count == 1
          end

          subnets.first[:subnet_id]
        end

        def compute_create_wait4running(instance_id)
          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            begin
              @ec2_client.wait_until(:instance_running, instance_ids:[instance_id]) do |waiter|
                timeout_deadline = Time.now + 5.minutes
                waiter.interval = 5      # number of seconds to sleep between attempts
                waiter.max_attempts = nil # maximum number of polling attempts

                waiter.before_attempt do |attempt|
                  throw(:failure, 'waited too long') if Time.now > timeout_deadline
                end
              end
            rescue ::Aws::Waiters::Errors::WaiterFailed
              fail Backends::Errors::ResourceNotValidError, 'Cannot proceed with attaching inline links, ' \
                                                            'instance is still not running. Timeout triggered!'
            end
          end
        end

      end
    end
  end
end
