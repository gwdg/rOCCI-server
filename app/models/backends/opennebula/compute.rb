module Backends
  module Opennebula
    class Compute < Base
      include Entitylike
      include AttributesTransferable
      include ResourceTplLocatable
      include MixinsAttachable

      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::Infrastructure::Compute
        end

        # :nodoc:
        def entity_identifier
          Occi::Infrastructure::Constants::COMPUTE_KIND
        end
      end

      # @see `Entitylike`
      def identifiers(_filter = Set.new)
        Set.new(pool(:virtual_machine, :info_mine).map { |vm| vm['ID'] })
      end

      # @see `Entitylike`
      def list(_filter = Set.new)
        coll = Occi::Core::Collection.new
        pool(:virtual_machine, :info_mine).each { |vm| coll << compute_from(vm) }
        coll
      end

      # @see `Entitylike`
      def instance(identifier)
        vm = ::OpenNebula::VirtualMachine.new_with_id(identifier, raw_client)
        client(Errors::Backend::EntityStateError) { vm.info }
        compute_from(vm)
      end

      # @see `Entitylike`
      def create(instance)
        vm_template = virtual_machine_from(instance)

        vm = ::OpenNebula::VirtualMachine.new(::OpenNebula::VirtualMachine.build_xml, raw_client)
        client(Errors::Backend::EntityCreateError) { vm.allocate(vm_template) }
        client(Errors::Backend::EntityStateError) { vm.info }

        vm['ID']
      end

      # @see `Entitylike`
      def delete(identifier)
        vm = ::OpenNebula::VirtualMachine.new_with_id(identifier, raw_client)
        client(Errors::Backend::EntityStateError) { vm.terminate(true) }
      end

      private

      # Converts a ONe virtual machine instance to a valid compute instance.
      #
      # @param virtual_machine [OpenNebula::VirtualMachine] instance to transform
      # @return [Occi::Infrastructure::Compute] transformed instance
      def compute_from(virtual_machine)
        compute = instance_builder.get(self.class.entity_identifier)

        attach_mixins! virtual_machine, compute
        transfer_attributes! virtual_machine, compute, Constants::Compute::TRANSFERABLE_ATTRIBUTES
        enable_actions! compute
        attach_links! compute

        compute
      end

      # Converts an OCCI compute instance to a valid ONe virtual machine template.
      #
      # @param storage [Occi::Infrastructure::Compute] instance to transform
      # @return [String] ONe template
      def virtual_machine_from(compute)
        os_tpl = server_model.find_by_identifier!(Occi::Infrastructure::Constants::OS_TPL_MIXIN)
        os_tpls = compute.select_mixins(os_tpl).map(&:term)
        raise Errors::Backend::EntityStateError, 'Single os_tpl not specified' unless os_tpls.one?

        template = ::OpenNebula::Template.new_with_id(os_tpls.first, raw_client)
        client(Errors::Backend::EntityStateError) { template.info }

        # TODO: set core attributes
        # TODO: set context
        # TODO: set resource_tpl (no PCI/GPU)
        # TODO: set inline links (securitygrouplink on existing NICs)
        # TODO: set availability_zone(s) in sched_reqs (append?)

        # TODO: append additional attributes (custom, user identity)
        # TODO: append GPU devices (PCI/GPU from resource_tpl)
        # TODO: append inline links (networkinterface w/ securitygrouplink, storagelink)

        template.template_str
      end

      # :nodoc:
      def attach_mixins!(virtual_machine, compute)
        compute << category_by_identifier!(Occi::Infrastructure::Constants::USER_DATA_MIXIN)
        compute << category_by_identifier!(Occi::Infrastructure::Constants::SSH_KEY_MIXIN)
        compute << server_model.find_regions.first

        attach_optional_mixin! compute, virtual_machine['HISTORY_RECORDS/HISTORY[last()]/CID'], :availability_zone
        attach_optional_mixin! compute, virtual_machine['TEMPLATE/TEMPLATE_ID'], :os_tpl

        res_tpl = resource_tpl_by_size(virtual_machine, Constants::Compute::COMPARABLE_ATTRIBUTES)
        compute << res_tpl if res_tpl
      end

      # :nodoc:
      def enable_actions!(compute)
        return unless compute['occi.compute.state'] == 'active'
        Constants::Compute::ACTIVE_ACTIONS.each { |a| compute.enable_action(a) }
      end

      # :nodoc:
      def attach_links!(compute)
        %i[networkinterface storagelink securitygrouplink].each do |type|
          backend_proxy.send(type).identifiers.each do |id|
            next unless id.start_with?("compute_#{compute.id}_")
            compute << backend_proxy.send(type).instance(id)
          end
        end
      end
    end
  end
end
