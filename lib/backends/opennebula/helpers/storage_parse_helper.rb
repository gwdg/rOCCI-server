module Backends
  module Opennebula
    module Helpers
      module StorageParseHelper
        def parse_backend_obj(backend_storage)
          storage = ::Occi::Infrastructure::Storage.new

          # include mixins stored in ON's VN template
          unless backend_storage['TEMPLATE/OCCI_STORAGE_MIXINS'].blank?
            backend_storage_mixins = backend_storage['TEMPLATE/OCCI_STORAGE_MIXINS'].split(' ')
            backend_storage_mixins.each do |mixin|
              storage.mixins << mixin unless mixin.blank?
            end
          end

          # include basic OCCI attributes
          basic_attrs = parse_basic_attrs(backend_storage)
          storage.attributes.merge! basic_attrs

          # include state information and available actions
          result = parse_state(backend_storage)
          storage.state = result.state
          result.actions.each { |a| storage.actions << a }

          storage
        end

        def parse_basic_attrs(backend_storage)
          basic_attrs = ::Occi::Core::Attributes.new

          basic_attrs['occi.core.id']  = backend_storage['ID']
          basic_attrs['occi.core.title'] = backend_storage['NAME'] if backend_storage['NAME']
          basic_attrs['occi.core.summary'] = backend_storage['TEMPLATE/DESCRIPTION'] unless backend_storage['TEMPLATE/DESCRIPTION'].blank?

          basic_attrs['occi.storage.size'] = backend_storage['SIZE'].to_f / 1024 if backend_storage['SIZE']

          basic_attrs
        end

        def parse_state(backend_storage)
          result = Hashie::Mash.new

          # In ON 4.4:
          #    IMAGE_STATES=%w{INIT READY USED DISABLED LOCKED ERROR
          #                    CLONE DELETE USED_PERS}
          #
          case backend_storage.state_str
          when 'READY'
            result.state = 'online'
            result.actions = %w|http://schemas.ogf.org/occi/infrastructure/storage/action#offline http://schemas.ogf.org/occi/infrastructure/storage/action#backup|
          when 'USED', 'CLONE', 'USED_PERS'
            result.state = 'online'
            result.actions = []
          when 'DISABLED'
            result.state = 'offline'
            result.actions = %w|http://schemas.ogf.org/occi/infrastructure/storage/action#online|
          when 'ERROR'
            result.state = 'degraded'
            result.actions = %w|http://schemas.ogf.org/occi/infrastructure/storage/action#online|
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
