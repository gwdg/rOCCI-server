module Backends
  module Opennebula
    class Storagelink < Base
      include Entitylike
      include AttributesTransferable
      include MixinsAttachable

      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::Infrastructure::Storagelink
        end

        # :nodoc:
        def entity_identifier
          Occi::Infrastructure::Constants::STORAGELINK_KIND
        end
      end

      # @see `Entitylike`
      def identifiers(_filter = Set.new)
        sls = Set.new
        pool(:virtual_machine, :info_mine).each do |vm|
          vm.each('TEMPLATE/DISK') do |disk|
            sls << Constants::Storagelink::ATTRIBUTES_CORE['occi.core.id'].call([disk, vm])
          end
        end
        sls
      end

      # @see `Entitylike`
      def list(_filter = Set.new)
        coll = Occi::Core::Collection.new
        pool(:virtual_machine, :info_mine).each do |vm|
          vm.each('TEMPLATE/DISK') { |disk| coll << storagelink_from(disk, vm) }
        end
        coll
      end

      # @see `Entitylike`
      def instance(identifier)
        matched = Constants::Storagelink::ID_PATTERN.match(identifier)
        vm = ::OpenNebula::VirtualMachine.new_with_id(matched[:compute], raw_client)
        client(Errors::Backend::EntityStateError) { vm.info }

        disk = nil
        vm.each("TEMPLATE/DISK[DISK_ID='#{matched[:disk]}']") { |vm_disk| disk = vm_disk }
        raise Errors::Backend::EntityNotFoundError, "DISK #{matched[:disk]} not found on #{vm['ID']}" unless disk

        storagelink_from(disk, vm)
      end

      # @see `Entitylike`
      def delete(identifier)
        matched = Constants::Storagelink::ID_PATTERN.match(identifier)
        vm = ::OpenNebula::VirtualMachine.new_with_id(matched[:compute], raw_client)
        client(Errors::Backend::EntityStateError) { vm.disk_detach(matched[:disk].to_i) }
      end

      private

      # Converts a ONe DISK + virtual machine instance to a valid storagelink instance.
      #
      # @param disk [Nokogiri::XMLElement] instance to transform
      # @param virtual_machine [OpenNebula::VirtualMachine] instance to transform
      # @return [Occi::Infrastructure::Storagelink] transformed instance
      def storagelink_from(disk, virtual_machine)
        storagelink = instance_builder.get(self.class.entity_identifier)

        attach_mixins! disk, virtual_machine, storagelink
        transfer_attributes!(
          [disk, virtual_machine], storagelink,
          Constants::Storagelink::TRANSFERABLE_ATTRIBUTES
        )
        storagelink.target_kind = category_by_identifier!(
          Occi::Infrastructure::Constants::STORAGE_KIND
        )

        storagelink
      end

      # :nodoc:
      def attach_mixins!(_disk, virtual_machine, storagelink)
        storagelink << server_model.find_regions.first

        attach_optional_mixin!(
          storagelink, virtual_machine['HISTORY_RECORDS/HISTORY[last()]/CID'],
          :availability_zone
        )
      end
    end
  end
end
