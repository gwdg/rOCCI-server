require 'ipaddr'

module Backends
  module Opennebula
    module Constants
      module Ipreservation
        # Attribute mapping hash for Core
        ATTRIBUTES_CORE = {
          'occi.core.id' => ->(vnet) { vnet['ID'] },
          'occi.core.title' => ->(vnet) { vnet['NAME'] },
          'occi.core.summary' => ->(vnet) { vnet['TEMPLATE/DESCRIPTION'] }
        }.freeze

        # Attribute mapping hash for Infra
        ATTRIBUTES_INFRA = {
          'occi.ipreservation.state' => ->(_vnet) { 'active' },
          'occi.network.state' => ->(_vnet) { 'active' },
          'occi.ipreservation.address' => ->(vnet) { IPAddr.new(vnet['AR_POOL/AR/IP']) },
          'occi.ipreservation.used' => ->(vnet) { vnet['USED_LEASES'] == '1' }
        }.freeze

        # All transferable attributes
        TRANSFERABLE_ATTRIBUTES = [ATTRIBUTES_CORE, ATTRIBUTES_INFRA].freeze
      end
    end
  end
end
