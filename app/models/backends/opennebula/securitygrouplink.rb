module Backends
  module Opennebula
    class Securitygrouplink < Base
      include Entitylike
      include AttributesTransferable
      include MixinsAttachable

      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::InfrastructureExt::SecurityGroupLink
        end

        # :nodoc:
        def entity_identifier
          Occi::InfrastructureExt::Constants::SECURITY_GROUP_LINK_KIND
        end
      end

      # @see `Entitylike`
      def identifiers(_filter = Set.new)
        sgls = Set.new
        pool(:virtual_machine, :info_mine).each do |vm|
          sec_groups(vm).each do |sg|
            sgls << Constants::Securitygrouplink::ATTRIBUTES_CORE['occi.core.id'].call([sg, vm])
          end
        end
        sgls
      end

      # @see `Entitylike`
      def list(_filter = Set.new)
        coll = Occi::Core::Collection.new
        pool(:virtual_machine, :info_mine).each do |vm|
          sec_groups(vm).each { |sg| coll << securitygrouplink_from(sg, vm) }
        end
        coll
      end

      # @see `Entitylike`
      def instance(identifier)
        matched = Constants::Securitygrouplink::ID_PATTERN.match(identifier)
        vm = ::OpenNebula::VirtualMachine.new_with_id(matched[:compute], raw_client)
        client(Errors::Backend::EntityStateError) { vm.info }

        securitygrouplink_from(matched[:sg], vm)
      end

      # @see `Entitylike`
      def delete(identifier)
        # TODO: how?
      end

      private

      # Converts a ONe SG + virtual machine instance to a valid securitygrouplink link instance.
      #
      # @param sg [String] instance ID to transform
      # @param virtual_machine [OpenNebula::VirtualMachine] instance to transform
      # @return [Occi::InfrastructureExt::SecurityGroupLink] transformed instance
      def securitygrouplink_from(sg, virtual_machine)
        sg_link = instance_builder.get(self.class.entity_identifier)

        attach_mixins! sg, virtual_machine, sg_link
        transfer_attributes!(
          [sg, virtual_machine], sg_link,
          Constants::Securitygrouplink::TRANSFERABLE_ATTRIBUTES
        )
        sg_link.target_kind = server_model.find_by_identifier!(
          Occi::InfrastructureExt::Constants::SECURITY_GROUP_KIND
        )

        sg_link
      end

      # :nodoc:
      def attach_mixins!(_sg, virtual_machine, sg_link)
        sg_link << server_model.find_regions.first

        attach_optional_mixin!(
          sg_link, virtual_machine['HISTORY_RECORDS/HISTORY[last()]/CID'],
          :availability_zone
        )
      end

      # :nodoc:
      def sec_groups(virtual_machine)
        s = Set.new
        virtual_machine.each_xpath('TEMPLATE/NIC/SECURITY_GROUPS') do |sgs|
          next if sgs.blank?
          sgs.split(',').each { |sg| s << sg }
        end
        s
      end
    end
  end
end
