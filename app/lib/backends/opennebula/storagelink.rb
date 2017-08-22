require 'backends/opennebula/base'

module Backends
  module Opennebula
    class Storagelink < Base
      include Backends::Helpers::Entitylike
      include Backends::Helpers::AttributesTransferable
      include Backends::Helpers::MixinsAttachable
      include Backends::Helpers::ErbRenderer

      # :nodoc:
      HELPER_NS = Backends::Opennebula::Helpers

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
        vm = pool_element(:virtual_machine, matched[:compute], :info)

        disk = nil
        vm.each("TEMPLATE/DISK[DISK_ID='#{matched[:disk]}']") { |vm_disk| disk = vm_disk }
        raise Errors::Backend::EntityNotFoundError, "DISK #{matched[:disk]} not found on #{vm['ID']}" unless disk

        storagelink_from(disk, vm)
      end

      # @see `Entitylike`
      def create(instance)
        vm = pool_element(:virtual_machine, instance.source_id, :info)
        disks = Backends::Opennebula::Helpers::Counter.xml_elements(vm, 'TEMPLATE/DISK')

        client(Errors::Backend::EntityCreateError) { vm.disk_attach disk_from(instance) }
        HELPER_NS::Waiter.wait_until(vm, 'RUNNING', Constants::Storagelink::ATTACH_TIMEOUT) do |nvm|
          unless HELPER_NS::Counter.xml_elements(nvm, 'TEMPLATE/DISK') > disks
            logger.error "Attaching IMAGE to VM[#{vm['ID']}] failed: #{vm['USER_TEMPLATE/ERROR']}"
            raise Errors::Backend::RemoteError, 'Could not attach storage to compute'
          end
        end

        Constants::Storagelink::ATTRIBUTES_CORE['occi.core.id'].call(
          [{ 'DISK_ID' => vm['TEMPLATE/DISK[last()]/DISK_ID'] }, vm]
        )
      end

      # @see `Entitylike`
      def delete(identifier)
        matched = Constants::Storagelink::ID_PATTERN.match(identifier)
        vm = pool_element(:virtual_machine, matched[:compute])
        client(Errors::Backend::EntityActionError) { vm.disk_detach(matched[:disk].to_i) }
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
        storagelink.target_kind = find_by_identifier!(
          Occi::Infrastructure::Constants::STORAGE_KIND
        )

        storagelink
      end

      # Converts an OCCI storagelink instance to a valid ONe virtual machine template DISK.
      #
      # @param storage [Occi::Infrastructure::Storagelink] instance to transform
      # @return [String] ONe template fragment
      def disk_from(storagelink)
        template_path = File.join(template_directory, 'compute_disk.erb')
        data = { instances: [storagelink] }
        erb_render template_path, data
      end

      # :nodoc:
      def attach_mixins!(_disk, virtual_machine, storagelink)
        storagelink << server_model.find_regions.first

        attach_optional_mixin!(
          storagelink, virtual_machine['HISTORY_RECORDS/HISTORY[last()]/CID'],
          :availability_zone
        )
      end

      # :nodoc:
      def whereami
        File.expand_path(File.dirname(__FILE__))
      end
    end
  end
end
