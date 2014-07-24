module Backends
  module Ec2
    module Helpers
      module ComputeActionHelper
        def compute_trigger_action_start(compute_id, attributes = Occi::Core::Attributes.new)
          compute_trigger_action_state_check(compute_id, 'http://schemas.ogf.org/occi/infrastructure/compute/action#start')

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            @ec2_client.start_instances(instance_ids: [compute_id])
          end

          true
        end

        def compute_trigger_action_restart(compute_id, attributes = Occi::Core::Attributes.new)
          compute_trigger_action_state_check(compute_id, 'http://schemas.ogf.org/occi/infrastructure/compute/action#restart')

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            @ec2_client.reboot_instances(instance_ids: [compute_id])
          end

          true
        end

        def compute_trigger_action_stop(compute_id, attributes = Occi::Core::Attributes.new)
          compute_trigger_action_state_check(compute_id, 'http://schemas.ogf.org/occi/infrastructure/compute/action#stop')

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            @ec2_client.stop_instances(instance_ids: [compute_id])
          end

          true
        end

        def compute_trigger_action_state_check(compute_id, action_type_identifier)
          result = compute_get(compute_id)

          unless result.actions.collect { |a| a.type_identifier }.include? action_type_identifier
            fail ::Backends::Errors::ResourceStateError,
                 "Given action is not allowed in state #{result.state.inspect}!"
          end

          true
        end
      end
    end
  end
end
