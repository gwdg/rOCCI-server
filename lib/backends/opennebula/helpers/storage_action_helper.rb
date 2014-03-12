module Backends
  module Opennebula
    module Helpers
      module StorageActionHelper
        def storage_trigger_action_online(storage_id, attributes = Occi::Core::Attributes.new)
          backend_object = storage_trigger_action_prolog(storage_id)
          storage_trigger_action_state_check(backend_object, 'http://schemas.ogf.org/occi/infrastructure/storage/action#online')

          rc = backend_object.enable
          check_retval(rc, Backends::Errors::ResourceActionError)

          true
        end

        def storage_trigger_action_offline(storage_id, attributes = Occi::Core::Attributes.new)
          backend_object = storage_trigger_action_prolog(storage_id)
          storage_trigger_action_state_check(backend_object, 'http://schemas.ogf.org/occi/infrastructure/storage/action#offline')

          rc = backend_object.disable
          check_retval(rc, Backends::Errors::ResourceActionError)

          true
        end

        def storage_trigger_action_backup(storage_id, attributes = Occi::Core::Attributes.new)
          backend_object = storage_trigger_action_prolog(storage_id)
          storage_trigger_action_state_check(backend_object, 'http://schemas.ogf.org/occi/infrastructure/storage/action#backup')

          rc = backend_object.clone("#{backend_object['NAME']}-#{DateTime.now.to_s.gsub(':', '_')}")
          check_retval(rc, Backends::Errors::ResourceActionError)

          true
        end

        def storage_trigger_action_prolog(storage_id)
          image = ::OpenNebula::Image.new(::OpenNebula::Image.build_xml(storage_id), @client)
          rc = image.info
          check_retval(rc, Backends::Errors::ResourceRetrievalError)

          image
        end

        def storage_trigger_action_state_check(backend_object, action_type_identifier)
          result = storage_parse_state(backend_object)

          unless result.actions.include? action_type_identifier
            fail ::Backends::Errors::ResourceStateError,
                 "Given action is not allowed in state #{result.state.inspect}!"
          end

          true
        end
      end
    end
  end
end
