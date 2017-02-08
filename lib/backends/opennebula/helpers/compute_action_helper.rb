module Backends
  module Opennebula
    module Helpers
      module ComputeActionHelper
        def trigger_action_start(compute_id, attributes = ::Occi::Core::Attributes.new)
          backend_object = trigger_action_prolog(compute_id)
          trigger_action_state_check(backend_object, 'http://schemas.ogf.org/occi/infrastructure/compute/action#start')

          rc = backend_object.resume
          check_retval(rc, Backends::Errors::ResourceActionError)

          true
        end

        def trigger_action_restart(compute_id, attributes = ::Occi::Core::Attributes.new)
          backend_object = trigger_action_prolog(compute_id)
          trigger_action_state_check(backend_object, 'http://schemas.ogf.org/occi/infrastructure/compute/action#restart')

          rc = backend_object.reboot(true)
          check_retval(rc, Backends::Errors::ResourceActionError)

          true
        end

        def trigger_action_stop(compute_id, attributes = ::Occi::Core::Attributes.new)
          backend_object = trigger_action_prolog(compute_id)
          trigger_action_state_check(backend_object, 'http://schemas.ogf.org/occi/infrastructure/compute/action#stop')

          rc = backend_object.poweroff(true)
          check_retval(rc, Backends::Errors::ResourceActionError)

          true
        end

        def trigger_action_suspend(compute_id, attributes = ::Occi::Core::Attributes.new)
          backend_object = trigger_action_prolog(compute_id)
          trigger_action_state_check(backend_object, 'http://schemas.ogf.org/occi/infrastructure/compute/action#suspend')

          rc = backend_object.suspend
          check_retval(rc, Backends::Errors::ResourceActionError)

          true
        end

        def trigger_action_save(compute_id, attributes = ::Occi::Core::Attributes.new)
          backend_object = trigger_action_prolog(compute_id)

          trigger_action_stop(compute_id, nil) unless backend_object.state_str == 'POWEROFF'
          compute_wait_for(backend_object, 'POWEROFF')

          rc = backend_object.save_as_template(
            attributes['name'].blank? ? "saved-compute-#{compute_id}-#{Time.now.utc.to_i}" : attributes['name'],
            true
          )
          check_retval(rc, Backends::Errors::ResourceActionError)

          # TODO: should we start the instance again? this is too slow for synchronous communication
          #backend_object = trigger_action_prolog(compute_id)
          #compute_wait_for(backend_object, 'POWEROFF')
          #trigger_action_start(compute_id, nil)
          trigger_action_save_mixins(rc)
        end

        def trigger_action_prolog(compute_id)
          virtual_machine = ::OpenNebula::VirtualMachine.new(::OpenNebula::VirtualMachine.build_xml(compute_id), @client)
          rc = virtual_machine.info
          check_retval(rc, Backends::Errors::ResourceRetrievalError)

          virtual_machine
        end

        def trigger_action_state_check(backend_object, action_type_identifier)
          result = parse_state(backend_object)

          unless result.actions.include? action_type_identifier
            fail ::Backends::Errors::ResourceStateError,
                 "Given action is not allowed in state #{result.state.inspect}!"
          end

          true
        end

        def trigger_action_save_mixins(template_id)
          cand = list_os_tpl.to_a.select { |mxn| mxn.term.end_with? "_#{template_id}" }
          fail Backends::Errors::ResourceRetrievalError,
               'Could not locate the newly created template!' if cand.count != 1
          Occi::Core::Mixins.new << cand.first
        end
      end
    end
  end
end
