module Backends
  module Opennebula
    class Networkinterface < Base
      include Entitylike
      include AttributesTransferable
      include MixinsAttachable

      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::Infrastructure::Networkinterface
        end

        # :nodoc:
        def entity_identifier
          Occi::Infrastructure::Constants::NETWORKINTERFACE_KIND
        end
      end

      # @see `Entitylike`
      def identifiers(_filter = Set.new)
        nis = Set.new
        pool(:virtual_machine, :info_mine).each do |vm|
          vm.each('TEMPLATE/NIC') do |nic|
            nis << Constants::Networkinterface::ATTRIBUTES_CORE['occi.core.id'].call([nic, vm])
          end
        end
        nis
      end

      # @see `Entitylike`
      def list(_filter = Set.new)
        coll = Occi::Core::Collection.new
        pool(:virtual_machine, :info_mine).each do |vm|
          vm.each('TEMPLATE/NIC') { |nic| coll << networkinterface_from(nic, vm) }
        end
        coll
      end

      # @see `Entitylike`
      def instance(identifier)
        matched = Constants::Networkinterface::ID_PATTERN.match(identifier)
        vm = ::OpenNebula::VirtualMachine.new_with_id(matched[:compute], raw_client)
        client(Errors::Backend::EntityStateError) { vm.info }

        nic = nil
        vm.each("TEMPLATE/NIC[NIC_ID='#{matched[:nic]}']") { |vm_nic| nic = vm_nic }
        raise Errors::Backend::EntityNotFoundError, "NIC #{matched[:nic]} not found on #{vm['ID']}" unless nic

        networkinterface_from(nic, vm)
      end

      # @see `Entitylike`
      def delete(identifier)
        matched = Constants::Networkinterface::ID_PATTERN.match(identifier)
        vm = ::OpenNebula::VirtualMachine.new_with_id(matched[:compute], raw_client)
        client(Errors::Backend::EntityStateError) { vm.nic_detach(matched[:nic].to_i) }
      end

      private

      # Converts a ONe NIC + virtual machine instance to a valid networkinterface instance.
      #
      # @param nic [Nokogiri::XMLElement] instance to transform
      # @param virtual_machine [OpenNebula::VirtualMachine] instance to transform
      # @return [Occi::Infrastructure::Networkinterface] transformed instance
      def networkinterface_from(nic, virtual_machine)
        networkinterface = instance_builder.get(self.class.entity_identifier)

        attach_mixins! nic, virtual_machine, networkinterface
        transfer_attributes!(
          [nic, virtual_machine], networkinterface,
          Constants::Networkinterface::TRANSFERABLE_ATTRIBUTES
        )
        # TODO: a better way to handle the following?
        fix_target! nic, networkinterface

        networkinterface
      end

      # :nodoc:
      def attach_mixins!(nic, virtual_machine, networkinterface)
        if nic['IP']
          networkinterface << category_by_identifier!(
            Occi::Infrastructure::Constants::IPNETWORKINTERFACE_MIXIN
          )
        end
        networkinterface << server_model.find_regions.first

        attach_optional_mixin!(
          networkinterface, virtual_machine['HISTORY_RECORDS/HISTORY[last()]/CID'],
          :availability_zone
        )
      end

      # :nodoc:
      def fix_target!(nic, networkinterface)
        tk = if ipreservation?(nic['NETWORK_ID'])
               networkinterface.target = URI.parse("/ipreservation/#{nic['NETWORK_ID']}")
               Occi::InfrastructureExt::Constants::IPRESERVATION_KIND
             else
               Occi::Infrastructure::Constants::NETWORK_KIND
             end
        networkinterface.target_kind = category_by_identifier!(tk)
      end

      # :nodoc:
      def ipreservation?(identifier)
        backend_proxy.ipreservation.identifiers.include?(identifier)
      end
    end
  end
end
