require 'backends/opennebula/base'

module Backends
  module Opennebula
    class Securitygrouplink < Base
      include Backends::Helpers::Entitylike
      include Backends::Helpers::AttributesTransferable
      include Backends::Helpers::MixinsAttachable

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
          Constants::Securitygrouplink::ID_EXTRACTOR.call(vm).each do |sg|
            sgls << Constants::Securitygrouplink::ATTRIBUTES_CORE['occi.core.id'].call([sg, vm])
          end
        end
        sgls
      end

      # @see `Entitylike`
      def list(_filter = Set.new)
        coll = Occi::Core::Collection.new
        pool(:virtual_machine, :info_mine).each do |vm|
          Constants::Securitygrouplink::ID_EXTRACTOR.call(vm).each { |sg| coll << securitygrouplink_from(sg, vm) }
        end
        coll
      end

      # @see `Entitylike`
      def instance(identifier)
        matched = Constants::Securitygrouplink::ID_PATTERN.match(identifier)
        vm = pool_element(:virtual_machine, matched[:compute], :info)
        securitygrouplink_from(matched[:sg], vm)
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
        sg_link.target_kind = find_by_identifier!(
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
    end
  end
end
