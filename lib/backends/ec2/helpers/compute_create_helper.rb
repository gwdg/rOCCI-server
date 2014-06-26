module Backends
  module Ec2
    module Helpers
      module ComputeCreateHelper

        COMPUTE_BASE64_REGEXP = /^[A-Za-z0-9+\/]+={0,2}$/
        COMPUTE_USER_DATA_SIZE_LIMIT = 16384

        def compute_create_with_os_tpl(compute)
          @logger.debug "[Backends] [Ec2Backend] Deploying #{compute.inspect}"

          os_tpl_mixins = compute.mixins.get_related_to(Occi::Infrastructure::OsTpl.mixin.type_identifier)
          os_tpl = os_tpl_mixins.first

          resource_tpl_mixins = compute.mixins.get_related_to(Occi::Infrastructure::ResourceTpl.mixin.type_identifier)
          resource_tpl = resource_tpl_mixins.first

          @logger.debug "[Backends] [Ec2Backend] Deploying with template #{os_tpl.term.inspect} in size #{resource_tpl.inspect}"
          os_tpl = os_tpl_list_term_to_image_id(os_tpl.term)
          resource_tpl = resource_tpl_list_term_to_itype(resource_tpl ? resource_tpl.term : 't1_micro')
          serialized_mixins = compute.mixins.to_a.map { |m| m.type_identifier }.join(' ')

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            ec2_response = @ec2_client.run_instances(
              image_id: os_tpl,
              instance_type: resource_tpl,
              min_count: 1, max_count: 1,
              user_data: compute_create_user_data(compute),
              monitoring: {
                enabled: false,
              },
              additional_info: serialized_mixins,
            )

            ec2_response.instances.first[:instance_id]
          end
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

      end
    end
  end
end
