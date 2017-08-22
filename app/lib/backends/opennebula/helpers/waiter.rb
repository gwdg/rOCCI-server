require 'timeout'

module Backends
  module Opennebula
    module Helpers
      module Waiter
        # Polling interval
        WAITER_STEP = 5

        # Early exit state
        EARLY_EXIT_ON = 'FAILURE'.freeze

        # Waits until the given `virtual_machine` changes state to `state` and
        # triggers validation procedure described in a block.
        #
        # @param virtual_machine [OpenNebula::VirtualMachine] VM to wait for
        # @param state [String] target state (LCM state by default)
        # @param timeout [Fixnum] wait for given number of seconds
        # @param type [Symbol] type of the state
        def wait_until(virtual_machine, state, timeout = 60, type = :lcm_state_str)
          Timeout.timeout(timeout, Errors::Backend::EntityTimeoutError) do
            loop do
              sleep WAITER_STEP
              client(Errors::Backend::EntityRetrievalError) { virtual_machine.info }
              early_fail! virtual_machine
              break if virtual_machine.send(type) == state
            end
          end
          yield virtual_machine if block_given?
        end

        # :nodoc:
        def early_fail!(virtual_machine)
          return unless virtual_machine.lcm_state_str.include?(EARLY_EXIT_ON)
          raise Errors::Backend::RemoteError, "VM #{virtual_machine['ID']} is stuck in state #{EARLY_EXIT_ON}"
        end
      end
    end
  end
end
