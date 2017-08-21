module Opennebula
  class ComputeResizeJob < ApplicationJob
    queue_as :opennebula

    # Default waiting step
    DEFAULT_STEP = 5

    # Default timeout in seconds
    DEFAULT_TIMEOUT = 900

    rescue_from(Errors::JobError) do |ex|
      logger.error "Delayed job failed: #{ex}"
    end

    # @param secret [String] credentials for ONe
    # @param endpoint [String] ONe XML RPC endpoint
    # @param identifier [String] virtual machine identifier
    # @param size [Hash] sizing attributes
    def perform(secret, endpoint, identifier, size)
      vm = ::OpenNebula::VirtualMachine.new_with_id(identifier, ::OpenNebula::Client.new(secret, endpoint))
      Timeout.timeout(DEFAULT_TIMEOUT) { wait_for_undeployed!(vm) }
      handle { vm.resize(size_template(size), true) }
      handle { vm.resume }
    end

    # :nodoc:
    def wait_for_undeployed!(vm)
      begin
        handle { vm.info }
        raise Errors::JobError, "Failed to undeploy VM #{vm['ID']}" if vm.lcm_state_str.include?('FAILURE')
        sleep DEFAULT_STEP
      end until vm.state_str == 'UNDEPLOYED'
    end

    # :nodoc:
    def size_template(size)
      resize_template = ''
      resize_template << "VCPU = #{size['occi.compute.cores']}\n"
      resize_template << "CPU = #{size['occi.compute.speed'] * size['occi.compute.cores']}\n"
      resize_template << "MEMORY = #{(size['occi.compute.memory'] * 1024).to_i}"
    end

    # :nodoc:
    def handle
      rc = yield
      raise rc.message if ::OpenNebula.is_error?(rc)
      rc
    rescue => ex
      raise Errors::JobError, ex.message
    end
  end
end
