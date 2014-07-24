module Backends
  module Ec2
    module Helpers
      module StorageActionHelper
        def storage_trigger_action_snapshot(storage_id, attributes = Occi::Core::Attributes.new)
          storage_trigger_action_state_check(storage_id, 'http://schemas.ogf.org/occi/infrastructure/storage/action#snapshot')

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            @ec2_client.create_snapshot(
              volume_id: storage_id,
              description: "Snapshot of #{storage_id} from #{DateTime.now}"
            )
          end

          true
        end

        def storage_trigger_action_state_check(storage_id, action_type_identifier)
          result = storage_get(storage_id)

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
