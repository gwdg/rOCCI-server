require 'ipaddr'

module Backends
  module Opennebula
    module Constants
      module Networkinterface
        # Pattern for matching IDs
        ID_PATTERN = /^compute_(?<compute>\d+)_nic_(?<nic>\d+)$/

        # Attribute mapping hash for Core
        ATTRIBUTES_CORE = {
          'occi.core.id' => ->(ary) { "compute_#{ary.last['ID']}_nic_#{ary.first['NIC_ID']}" },
          'occi.core.title' => ->(ary) { "NIC #{ary.first['NIC_ID']} for compute #{ary.last['ID']}" },
          'occi.core.source' => ->(ary) { URI.parse("/compute/#{ary.last['ID']}") },
          'occi.core.target' => ->(ary) { URI.parse("/network/#{ary.first['NETWORK_ID']}") }
        }.freeze

        # Attribute mapping hash for Infra
        ATTRIBUTES_INFRA = {
          'occi.networkinterface.interface' => ->(ary) { "eth#{ary.first['NIC_ID']}" },
          'occi.networkinterface.mac' => ->(ary) { ary.first['MAC'] },
          'occi.networkinterface.state' => ->(ary) { ary.last.lcm_state_str == 'RUNNING' ? 'active' : 'inactive' },
          'occi.networkinterface.address' => ->(ary) { IPAddr.new(ary.first['IP']) },
          'occi.networkinterface.allocation' => ->(_ary) { nil },
          # 'occi.networkinterface.gateway' => ->(ary) { HOW? }
        }.freeze

        # All transferable attributes
        TRANSFERABLE_ATTRIBUTES = [ATTRIBUTES_CORE, ATTRIBUTES_INFRA].freeze
      end
    end
  end
end
