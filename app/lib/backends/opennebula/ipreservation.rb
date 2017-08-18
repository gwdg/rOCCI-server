require 'backends/opennebula/base'

module Backends
  module Opennebula
    class Ipreservation < Base
      include Backends::Helpers::Entitylike
      include Backends::Helpers::AttributesTransferable
      include Backends::Helpers::MixinsAttachable

      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::InfrastructureExt::IPReservation
        end

        # :nodoc:
        def entity_identifier
          Occi::InfrastructureExt::Constants::IPRESERVATION_KIND
        end
      end

      # @see `Entitylike`
      def identifiers(_filter = Set.new)
        vnets = Set.new
        pool(:virtual_network, :info_mine).each do |vnet|
          next unless single_reservation?(vnet)
          vnets << vnet['ID']
        end
        vnets
      end

      # @see `Entitylike`
      def list(_filter = Set.new)
        coll = Occi::Core::Collection.new
        pool(:virtual_network, :info_mine).each do |vnet|
          next unless single_reservation?(vnet)
          coll << ipreservation_from(vnet)
        end
        coll
      end

      # @see `Entitylike`
      def instance(identifier)
        ipreservation_from pool_element(:virtual_network, identifier, :info)
      end

      # @see `Entitylike`
      def create(instance)
        vnet = pool_element(:virtual_network, instance.floatingippool.term)
        res_name = instance['occi.core.title'] || ::SecureRandom.uuid
        res_id = client(Errors::Backend::EntityCreateError) { vnet.reserve(res_name, 1) }
        res_id.to_s
      end

      # @see `Entitylike`
      def delete(identifier)
        vnet = pool_element(:virtual_network, identifier)
        client(Errors::Backend::EntityActionError) { vnet.delete }
      end

      private

      # Converts a ONe virtual network instance to a valid ipreservation instance.
      #
      # @param virtual_network [OpenNebula::VirtualNetwork] instance to transform
      # @return [Occi::InfrastructureExt::IPReservation] transformed instance
      def ipreservation_from(virtual_network)
        ipres = instance_builder.get(self.class.entity_identifier)

        attach_mixins! virtual_network, ipres
        transfer_attributes! virtual_network, ipres, Constants::Ipreservation::TRANSFERABLE_ATTRIBUTES

        ipres
      end

      # :nodoc:
      def attach_mixins!(virtual_network, ipres)
        ipres << server_model.find_regions.first
        attach_optional_mixin! ipres, virtual_network['PARENT_NETWORK_ID'], :floatingippool

        virtual_network.each_xpath('CLUSTERS/ID') do |cid|
          attach_optional_mixin! ipres, cid, :availability_zone
        end
      end

      # :nodoc:
      def single_reservation?(virtual_network)
        return unless virtual_network['PARENT_NETWORK_ID']

        ips = 0
        virtual_network.each_xpath('AR_POOL/AR/IP') { ips += 1 }
        return unless ips == 1

        virtual_network['AR_POOL/AR/SIZE'].to_i == 1
      end
    end
  end
end
