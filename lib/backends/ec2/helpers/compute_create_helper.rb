module Backends
  module Ec2
    module Helpers
      module ComputeCreateHelper

        COMPUTE_BASE64_REGEXP = /^[A-Za-z0-9+\/]+={0,2}$/
        COMPUTE_USER_DATA_SIZE_LIMIT = 16384

        def compute_create_with_os_tpl(compute)
          @logger.debug "[Backends] [Ec2Backend] Deploying #{compute.inspect}"

          # generate and amend inst options
          instance_opts = compute_create_instance_opts(compute)
          instance_opts = compute_create_add_inline_ntwrkintfs_vdc(compute, instance_opts)
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

        def compute_create_add_inline_ntwrkintfs_vdc(compute, instance_opts)
          # TODO: impl
          # TODO: add subnet_id to instance_opts
          # TODO: call compute_create_get_first_vdc_subnet(vdc_id)
          instance_opts
        end

        def compute_create_add_inline_strglnks(compute, instance_id)
          strglnks = compute.links.to_a.select { |link| link.kind.type_identifier == 'http://schemas.ogf.org/occi/infrastructure#storagelink' }

          strglnks.each do |storagelink|
            @logger.debug "[Backends] [Ec2Backend] Attaching inline storage #{storagelink.target.inspect} to \"/compute/#{instance_id}\""

            storagelink.source = "/compute/#{instance_id}"
            compute_attach_storage(storagelink)
          end
        end

        def compute_create_add_inline_ntwrkintfs_elastic(compute, instance_id)
          ntwrkintfs = compute.links.to_a.select { |link| link.kind.type_identifier == 'http://schemas.ogf.org/occi/infrastructure#networkinterface' }

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

          tags
        end

        def compute_create_get_first_vdc_subnet(vdc_id)
          # TODO: impl
        end

      end
    end
  end
end
