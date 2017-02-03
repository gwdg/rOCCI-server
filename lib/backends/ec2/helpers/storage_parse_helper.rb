module Backends
  module Ec2
    module Helpers
      module StorageParseHelper
        def parse_backend_obj(backend_storage)
          storage = ::Occi::Infrastructure::Storage.new

          storage.attributes['occi.core.id'] = backend_storage[:volume_id]
          storage.attributes['occi.core.title'] =
            if backend_storage[:tags].select { |tag| tag[:key] == 'Name' }.any?
              backend_storage[:tags].select { |tag| tag[:key] == 'Name' }.first[:value]
            else
              "rOCCI-server volume #{backend_storage[:size]}GB"
            end
          storage.attributes['occi.storage.size'] = backend_storage[:size]

          # include state information and available actions
          result = parse_state(backend_storage)
          storage.state = result.state
          result.actions.each { |a| storage.actions << a }

          storage
        end

        private

        def parse_state(backend_storage)
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
