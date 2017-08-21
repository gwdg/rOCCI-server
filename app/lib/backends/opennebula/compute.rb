require 'backends/opennebula/base'

module Backends
  module Opennebula
    class Compute < Base
      include Backends::Helpers::Entitylike
      include Backends::Helpers::AttributesTransferable
      include Backends::Helpers::ResourceTplLocatable
      include Backends::Helpers::MixinsAttachable
      include Backends::Helpers::ErbRenderer
      include Backends::Opennebula::Helpers::VirtualMachineMutators

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
        compute_from pool_element(:virtual_machine, identifier, :info)
      end

      # @see `Entitylike`
      def create(instance)
        pool_element_allocate(:virtual_machine, virtual_machine_from(instance))['ID']
      end

      # @see `Entitylike`
      def partial_update(identifier, fragments)
        res_tpl = fragments[:mixins].detect do |m|
          m.respond_to?(:depends?) && m.depends?(Occi::Infrastructure::Mixins::ResourceTpl.new)
        end
        raise Errors::Backend::EntityActionError, 'Resource template not provided' unless res_tpl

        vm = pool_element(:virtual_machine, identifier, :info)
        client(Errors::Backend::EntityActionError) { vm.undeploy(true) } unless vm.state_str == 'UNDEPLOYED'

        ::Opennebula::ComputeResizeJob.perform_later(
          client_secret(options), options.fetch(:endpoint),
          identifier, serializable_attributes(res_tpl.attributes)
        )

        instance identifier
      end

      # @see `Entitylike`
      def trigger(identifier, action_instance)
        name = action_instance.action.term
        vm = pool_element(:virtual_machine, identifier)
        client(Errors::Backend::EntityActionError) do
          Constants::Compute::ACTIONS[name].call(vm, action_instance)
        end

        # TODO: return os_tpl mixin for `save`
        Occi::Core::Collection.new
      end

      # @see `Entitylike`
      def delete(identifier)
        vm = pool_element(:virtual_machine, identifier)
        client(Errors::Backend::EntityActionError) { vm.terminate(true) }
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
        os_tpl = compute.os_tpl.term
        template = pool_element(:template, os_tpl, :info)

        modify_basic! template, compute, os_tpl
        %i[set_context! set_size! set_security_groups! set_cluster!].each { |mtd| send(mtd, template, compute) }

        template = template.template_str
        %i[add_custom! add_gpu! add_nics! add_disks!].each { |mtd| send(mtd, template, compute) }

        template
      end

      # :nodoc:
      def attach_mixins!(virtual_machine, compute)
        compute << find_by_identifier!(Occi::Infrastructure::Constants::USER_DATA_MIXIN)
        compute << find_by_identifier!(Occi::Infrastructure::Constants::SSH_KEY_MIXIN)
        compute << server_model.find_regions.first

        attach_optional_mixin! compute, virtual_machine['HISTORY_RECORDS/HISTORY[last()]/CID'], :availability_zone
        attach_optional_mixin! compute, virtual_machine['TEMPLATE/TEMPLATE_ID'], :os_tpl

        res_tpl = resource_tpl_by_size(virtual_machine, Constants::Compute::COMPARABLE_ATTRIBUTES)
        compute << res_tpl if res_tpl
      end

      # :nodoc:
      def enable_actions!(compute)
        actions = case compute['occi.compute.state']
                  when 'active'
                    Constants::Compute::ACTIVE_ACTIONS.keys
                  when 'inactive'
                    Constants::Compute::INACTIVE_ACTIONS.keys
                  else
                    []
                  end

        actions.each { |a| compute.enable_action(a) }
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

      # :nodoc:
      def serializable_attributes(attributes)
        Hash[attributes.map { |k, v| [k, v.default] }]
      end

      # :nodoc:
      def whereami
        File.expand_path(File.dirname(__FILE__))
      end
    end
  end
end
