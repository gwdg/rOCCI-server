module Opennebula
  class ComputeResizeJob < ApplicationJob
    queue_as :opennebula

    # Default timeout in seconds
    DEFAULT_TIMEOUT = 900

    rescue_from(Errors::JobError) do |ex|
      logger.error "Delayed job failed: #{ex}"
    end

    rescue_from(Errors::Backend::EntityTimeoutError) do |_ex|
      logger.error "Timed out while waiting for job completion [#{DEFAULT_TIMEOUT}s]"
    end

    rescue_from(Errors::Backend::EntityRetrievalError) do |ex|
      logger.error "Failed to get instance state when waiting: #{ex}"
    end

    rescue_from(Errors::Backend::RemoteError) do |ex|
      logger.fatal "Failed during transition: #{ex}"
    end

    # @param secret [String] credentials for ONe
    # @param endpoint [String] ONe XML RPC endpoint
    # @param identifier [String] virtual machine identifier
    # @param size [Hash] sizing attributes
    def perform(secret, endpoint, identifier, size)
      vm = ::OpenNebula::VirtualMachine.new_with_id(identifier, ::OpenNebula::Client.new(secret, endpoint))
      ::Backends::Opennebula::Helpers::Waiter.wait_until(vm, 'UNDEPLOYED', DEFAULT_TIMEOUT, :state_str)
      handle { vm.resize(size_template(size), true) }
      handle { vm.resume }
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
