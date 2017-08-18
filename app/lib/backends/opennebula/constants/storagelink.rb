module Backends
  module Opennebula
    module Constants
      module Storagelink
        # Pattern for matching IDs
        ID_PATTERN = /^compute_(?<compute>\d+)_disk_(?<disk>\d+)$/

        # Attach timeout
        ATTACH_TIMEOUT = 120

        # Attribute mapping hash for Core
        ATTRIBUTES_CORE = {
          'occi.core.id' => ->(ary) { "compute_#{ary.last['ID']}_disk_#{ary.first['DISK_ID']}" },
          'occi.core.title' => ->(ary) { "DISK #{ary.first['DISK_ID']} for compute #{ary.last['ID']}" },
          'occi.core.source' => ->(ary) { URI.parse("/compute/#{ary.last['ID']}") },
          'occi.core.target' => ->(ary) { URI.parse("/storage/#{ary.first['IMAGE_ID']}") }
        }.freeze

        # Attribute mapping hash for Infra
        ATTRIBUTES_INFRA = {
          'occi.storagelink.deviceid' => ->(ary) { ary.first['TARGET'].to_s },
          # 'occi.storagelink.mountpoint' => ->(ary) { HOW? },
          'occi.storagelink.state' => ->(ary) { ary.last.lcm_state_str == 'RUNNING' ? 'active' : 'inactive' }
        }.freeze

        # All transferable attributes
        TRANSFERABLE_ATTRIBUTES = [ATTRIBUTES_CORE, ATTRIBUTES_INFRA].freeze
      end
    end
  end
end
