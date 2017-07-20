module Backends
  module Opennebula
    class Network < Base
      include Entitylike
      include AttributesTransferable
      include MixinsAttachable

      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::Infrastructure::Network
        end

        # :nodoc:
        def entity_identifier
          Occi::Infrastructure::Constants::NETWORK_KIND
        end
      end

      # @see `Entitylike`
      def identifiers(_filter = Set.new)
        vnets = Set.new
        excluded = backend_proxy.ipreservation.identifiers
        pool(:virtual_network, :info_all).each do |vnet|
          next if excluded.include?(vnet['ID']) # skip reservations
          vnets << vnet['ID']
        end
        vnets
      end

      # @see `Entitylike`
      def list(_filter = Set.new)
        coll = Occi::Core::Collection.new
        excluded = backend_proxy.ipreservation.identifiers
        pool(:virtual_network, :info_mine).each do |vnet|
          next if excluded.include?(vnet['ID']) # skip reservations
          coll << network_from(vnet)
        end
        coll
      end

      # @see `Entitylike`
      def instance(identifier)
        vnet = ::OpenNebula::VirtualNetwork.new_with_id(identifier, raw_client)
        client(Errors::Backend::EntityStateError) { vnet.info }
        network_from(vnet)
      end

      # @see `Entitylike`
      def delete(identifier)
        vnet = ::OpenNebula::VirtualNetwork.new_with_id(identifier, raw_client)
        client(Errors::Backend::EntityStateError) { vnet.delete }
      end

      private

      # Converts a ONe virtual network instance to a valid network instance.
      #
      # @param virtual_network [OpenNebula::VirtualNetwork] instance to transform
      # @return [Occi::Infrastructure::Network] transformed instance
      def network_from(virtual_network)
        network = instance_builder.get(self.class.entity_identifier)

        attach_mixins! virtual_network, network
        transfer_attributes! virtual_network, network, Constants::Network::TRANSFERABLE_ATTRIBUTES
        set_network_type! virtual_network, network

        network
      end

      # :nodoc:
      def attach_mixins!(virtual_network, network)
        if virtual_network['AR_POOL/AR/IP']
          network << server_model.find_by_identifier!(Occi::Infrastructure::Constants::IPNETWORK_MIXIN)
        end
        network << server_model.find_regions.first

        virtual_network.each_xpath('CLUSTERS/ID') do |cid|
          attach_optional_mixin! network, cid, :availability_zone
        end
      end

      # :nodoc:
      def set_network_type!(virtual_network, network)
        mxn = case virtual_network['TEMPLATE/NETWORK_TYPE']
              when 'public', 'PUBLIC'
                Occi::InfrastructureExt::Constants::PUBLIC_NET_MIXIN
              when 'private', 'PRIVATE'
                Occi::InfrastructureExt::Constants::PRIVATE_NET_MIXIN
              when 'nat', 'NAT'
                Occi::InfrastructureExt::Constants::NAT_NET_MIXIN
              end

        network << server_model.find_by_identifier!(mxn) if mxn
      end
    end
  end
end
