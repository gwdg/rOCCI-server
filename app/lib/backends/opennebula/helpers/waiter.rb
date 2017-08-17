require 'timeout'

module Backends
  module Opennebula
    module Helpers
      module Waiter
        # Polling interval
        WAITER_STEP = 5

        # Waits until the given `virtual_machine` changes state to `state` and
        # triggers validation procedure described in a block.
        #
        # @param virtual_machine [OpenNebula::VirtualMachine] VM to wait for
        # @param state [String] target state (LCM state)
        # @param timeout [Fixnum] wait for given number of seconds
        def wait_until(virtual_machine, state, timeout = 60)
          raise Errors::Backend::InternalError, 'Block is a mandatory argument' unless block_given?

          Timeout.timeout(timeout) do
            loop do
              sleep WAITER_STEP
              client(Errors::Backend::EntityStateError) { virtual_machine.info }
              break if virtual_machine.lcm_state_str == state
            end
          end

          yield virtual_machine
        end
      end
    end
  end
end
