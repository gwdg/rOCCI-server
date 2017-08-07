module Backends
  module Opennebula
    class Network < Base
      include Entitylike
      include AttributesTransferable
      include MixinsAttachable
      include ErbRenderer

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
        pool(:virtual_network, :info_all).each do |vnet|
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
      def create(instance)
        vnet_template = virtual_network_from(instance)
        az = server_model.find_by_identifier!(Occi::InfrastructureExt::Constants::AVAILABILITY_ZONE_MIXIN)
        azs = instance.select_mixins(az).map(&:term)

        # TODO: multi-cluster networks
        raise Errors::Backend::EntityStateError, 'Single availability zone not specified' if azs.many?
        cid = (azs.first || default_cluster).to_i

        vnet = ::OpenNebula::VirtualNetwork.new(::OpenNebula::VirtualNetwork.build_xml, raw_client)
        client(Errors::Backend::EntityCreateError) { vnet.allocate(vnet_template, cid) }
        client(Errors::Backend::EntityStateError) { vnet.info }

        vnet['ID']
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

      # Converts an OCCI network instance to a valid ONe virtual network template.
      #
      # @param storage [Occi::Infrastructure::Network] instance to transform
      # @return [String] ONe template
      def virtual_network_from(network)
        template_path = File.join(template_directory, 'network.erb')
        data = { instance: network, identity: active_identity }
        data[:configuration] = { phydev: default_network_phydev }
        erb_render template_path, data
      end

      # :nodoc:
      def attach_mixins!(virtual_network, network)
        if virtual_network['AR_POOL/AR/IP']
          network << category_by_identifier!(Occi::Infrastructure::Constants::IPNETWORK_MIXIN)
        end
        network << server_model.find_regions.first

        virtual_network.each_xpath('CLUSTERS/ID') do |cid|
          attach_optional_mixin! network, cid, :availability_zone
        end
      end

      # :nodoc:
      def set_network_type!(virtual_network, network)
        return unless virtual_network['TEMPLATE/NETWORK_TYPE'].present?

        mxn = case virtual_network['TEMPLATE/NETWORK_TYPE'].downcase
              when 'public'
                Occi::InfrastructureExt::Constants::PUBLIC_NET_MIXIN
              when 'private'
                Occi::InfrastructureExt::Constants::PRIVATE_NET_MIXIN
              when 'nat'
                Occi::InfrastructureExt::Constants::NAT_NET_MIXIN
              end

        network << category_by_identifier!(mxn) if mxn
      end

      # :nodoc:
      def whereami
        File.expand_path(File.dirname(__FILE__))
      end
    end
  end
end
