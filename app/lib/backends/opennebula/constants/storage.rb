module Backends
  module Opennebula
    module Constants
      module Storage
        # State map
        STATE_MAP = {
          'READY' => 'online',
          'USED' => 'online',
          'ERROR' => 'degraded',
          'USED_PERS' => 'online'
        }.freeze

        # Attribute mapping hash for Core
        ATTRIBUTES_CORE = {
          'occi.core.id' => ->(image) { image['ID'] },
          'occi.core.title' => ->(image) { image['NAME'] },
          'occi.core.summary' => ->(image) { image['TEMPLATE/DESCRIPTION'] }
        }.freeze

        # Attribute mapping hash for Infra
        ATTRIBUTES_INFRA = {
          'occi.storage.state' => ->(image) { STATE_MAP[image.state_str] || 'offline' },
          'occi.storage.size' => ->(image) { image['SIZE'].to_f / 1024 }
        }.freeze

        # All transferable attributes
        TRANSFERABLE_ATTRIBUTES = [ATTRIBUTES_CORE, ATTRIBUTES_INFRA].freeze

        # Actions to enable when online
        ONLINE_ACTIONS = {
          'backup' => ->(image, _ai) { image.clone "storage-#{image['ID']}-#{Time.now.utc.to_i}" }
        }.freeze
      end
    end
  end
end
