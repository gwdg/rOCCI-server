module Backends
  module Ec2
    module Helpers
      module StorageParseHelper

        def storage_parse_backend_obj(backend_storage)
          storage = Occi::Infrastructure::Storage.new

          storage.mixins << 'http://schemas.ec2.aws.amazon.com/occi/infrastructure/storage#aws_ec2_ebs_volume'

          storage.attributes['occi.core.id'] = backend_storage[:volume_id]
          storage.attributes['occi.core.title'] = if backend_storage[:tags].select { |tag| tag[:key] == 'Name' }.any?
            backend_storage[:tags].select { |tag| tag[:key] == 'Name' }.first[:value]
          else
            "rOCCI-server volume #{backend_storage[:size]}GB"
          end
          storage.attributes['occi.storage.size'] = backend_storage[:size]

          storage.attributes['com.amazon.aws.ec2.availability_zone'] = backend_storage[:availability_zone] if backend_storage[:availability_zone]
          storage.attributes['com.amazon.aws.ec2.state'] = backend_storage[:state] if backend_storage[:state]
          storage.attributes['com.amazon.aws.ec2.volume_type'] = backend_storage[:volume_type] if backend_storage[:volume_type]
          storage.attributes['com.amazon.aws.ec2.iops'] = backend_storage[:iops] if backend_storage[:iops]
          storage.attributes['com.amazon.aws.ec2.encrypted'] = backend_storage[:encrypted] unless backend_storage[:encrypted].nil?

          # include state information and available actions
          result = storage_parse_state(backend_storage)
          storage.state = result.state
          result.actions.each { |a| storage.actions << a }

          storage
        end

        private

        def storage_parse_state(backend_storage)
          result = Hashie::Mash.new

          # In EC2:
          #   creating | available | in-use | deleting | deleted | error
          case backend_storage[:state]
          when 'available', 'in-use'
            result.state = 'online'
            result.actions = %w|http://schemas.ogf.org/occi/infrastructure/storage/action#snapshot|
          when 'error'
            result.state = 'degraded'
            result.actions = []
          else
            result.state = 'offline'
            result.actions = []
          end

          result
        end

      end
    end
  end
end
