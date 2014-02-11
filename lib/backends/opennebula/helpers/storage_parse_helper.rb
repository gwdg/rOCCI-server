module Backends
  module Opennebula
    module Helpers

      module StorageParseHelper

        def storage_parse_backend_obj(backend_storage)
          storage = Occi::Infrastructure::Storage.new

          # include some basic mixins
          storage.mixins << 'http://opennebula.org/occi/infrastructure#storage'

          # include mixins stored in ON's VN template
          unless backend_storage['TEMPLATE/OCCI_STORAGE_MIXINS'].blank?
            backend_storage_mixins = backend_storage['TEMPLATE/OCCI_STORAGE_MIXINS'].split(' ')
            backend_storage_mixins.each do |mixin|
              storage.mixins << mixin unless mixin.blank?
            end
          end

          storage.id  = backend_storage['ID']
          storage.title = backend_storage['NAME'] if backend_storage['NAME']
          storage.summary = backend_storage['TEMPLATE/DESCRIPTION'] if backend_storage['TEMPLATE/DESCRIPTION']

          storage.size = backend_storage['SIZE'].to_f/1024 if backend_storage['SIZE']

          storage.attributes['org.opennebula.storage.id'] = backend_storage['ID']
          storage.attributes['org.opennebula.storage.type'] = backend_storage.type_str

          if backend_storage['PERSISTENT'].blank? || backend_storage['PERSISTENT'].to_i == 0
            storage.attributes['org.opennebula.storage.persistent'] = "NO"
          else
            storage.attributes['org.opennebula.storage.persistent'] = "YES"
          end

          storage.attributes['org.opennebula.storage.dev_prefix'] = backend_storage['TEMPLATE/DEV_PREFIX'] if backend_storage['TEMPLATE/DEV_PREFIX']
          storage.attributes['org.opennebula.storage.bus'] = backend_storage['TEMPLATE/BUS'] if backend_storage['TEMPLATE/BUS']
          storage.attributes['org.opennebula.storage.driver'] = backend_storage['TEMPLATE/DRIVER'] if backend_storage['TEMPLATE/DRIVER']

          result = storage_parse_set_state(backend_storage)
          storage.state = result.state
          result.actions.each { |a| storage.actions << a }

          storage
        end

        def storage_parse_set_state(backend_storage)
          result = Hashie::Mash.new

          # In ON 4.4:
          #    IMAGE_STATES=%w{INIT READY USED DISABLED LOCKED ERROR
          #                    CLONE DELETE USED_PERS}
          #
          case backend_storage.state_str
          when "READY"
            result.state = "online"
            result.actions = %w|http://schemas.ogf.org/occi/infrastructure/storage/action#offline http://schemas.ogf.org/occi/infrastructure/storage/action#backup|
          when "USED", "CLONE", "USED_PERS"
            result.state = "online"
            result.actions = []
          when "DISABLED"
            result.state = "offline"
            result.actions = %w|http://schemas.ogf.org/occi/infrastructure/storage/action#online|
          when "ERROR"
            result.state = "degraded"
            result.actions = %w|http://schemas.ogf.org/occi/infrastructure/storage/action#online|
          else
            result.state = "offline"
            result.actions = []
          end

          result
        end

      end

    end
  end
end
