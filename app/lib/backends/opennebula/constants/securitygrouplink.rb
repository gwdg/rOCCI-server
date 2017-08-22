module Backends
  module Opennebula
    module Constants
      module Securitygrouplink
        # Pattern for matching IDs
        ID_PATTERN = /^compute_(?<compute>\d+)_sg_(?<sg>\d+)$/

        # Extractor for SG IDs (from ONe VM)
        ID_EXTRACTOR = lambda do |virtual_machine|
          set = Set.new
          virtual_machine.each_xpath('TEMPLATE/NIC/SECURITY_GROUPS') do |sgs|
            next if sgs.blank?
            sgs.split(',').each { |sg| set << sg }
          end
          set
        end

        # Attribute mapping hash for Core
        ATTRIBUTES_CORE = {
          'occi.core.id' => ->(ary) { "compute_#{ary.last['ID']}_sg_#{ary.first}" },
          'occi.core.title' => ->(ary) { "SG #{ary.first} for compute #{ary.last['ID']}" },
          'occi.core.source' => ->(ary) { URI.parse("/compute/#{ary.last['ID']}") },
          'occi.core.target' => ->(ary) { URI.parse("/securitygroup/#{ary.first}") }
        }.freeze

        # Attribute mapping hash for Infra
        ATTRIBUTES_INFRA = {
          'occi.securitygrouplink.state' => ->(ary) { ary.last.lcm_state_str == 'RUNNING' ? 'active' : 'inactive' }
        }.freeze

        # All transferable attributes
        TRANSFERABLE_ATTRIBUTES = [ATTRIBUTES_CORE, ATTRIBUTES_INFRA].freeze
      end
    end
  end
end
