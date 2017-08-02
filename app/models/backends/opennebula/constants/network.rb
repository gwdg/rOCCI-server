module Backends
  module Opennebula
    module Constants
      module Network
        # Attribute mapping hash for Core
        ATTRIBUTES_CORE = {
          'occi.core.id' => ->(vnet) { vnet['ID'] },
          'occi.core.title' => ->(vnet) { vnet['NAME'] },
          'occi.core.summary' => ->(vnet) { vnet['TEMPLATE/DESCRIPTION'] }
        }.freeze

        # Commonly used lambdas
        VLAN_LAMBDA = ->(vnet) { vnet['VLAN_ID'].present? ? vnet['VLAN_ID'].to_i : nil }

        # Attribute mapping hash for Infra
        ATTRIBUTES_INFRA = {
          'occi.network.state' => ->(_vnet) { 'active' },
          'occi.network.vlan' => VLAN_LAMBDA,
          'occi.network.label' => VLAN_LAMBDA,
          'occi.network.address' => lambda do |vnet|
            vnet['AR_POOL/AR/IP'] ? vnet['TEMPLATE/CIDR_NETWORK_ADDRESS'] : nil
          end,
          'occi.network.allocation' => lambda do |vnet|
            vnet['AR_POOL/AR/IP'] ? 'dynamic' : nil
          end,
          'occi.network.gateway' => lambda do |vnet|
            vnet['AR_POOL/AR/IP'] ? vnet['TEMPLATE/GATEWAY'] : nil
          end
        }.freeze

        # All transferable attributes
        TRANSFERABLE_ATTRIBUTES = [ATTRIBUTES_CORE, ATTRIBUTES_INFRA].freeze
      end
    end
  end
end
