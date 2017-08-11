require 'ipaddr'

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
          'occi.network.label' => ->(vnet) { VLAN_LAMBDA.call(vnet).to_s },
          'occi.network.address' => lambda do |vnet|
            return unless vnet['TEMPLATE/NETWORK_ADDRESS'].present? && vnet['TEMPLATE/NETWORK_MASK'].present?
            IPAddr.new "#{vnet['TEMPLATE/NETWORK_ADDRESS']}/#{vnet['TEMPLATE/NETWORK_MASK']}"
          end,
          'occi.network.allocation' => lambda do |vnet|
            return if vnet['TEMPLATE/NETWORK_TYPE'].blank?
            %w[public nat].include?(vnet['TEMPLATE/NETWORK_TYPE'].downcase) ? 'dynamic' : 'static'
          end,
          'occi.network.gateway' => lambda do |vnet|
            return if vnet['TEMPLATE/GATEWAY'].blank?
            IPAddr.new vnet['TEMPLATE/GATEWAY']
          end
        }.freeze

        # All transferable attributes
        TRANSFERABLE_ATTRIBUTES = [ATTRIBUTES_CORE, ATTRIBUTES_INFRA].freeze
      end
    end
  end
end
