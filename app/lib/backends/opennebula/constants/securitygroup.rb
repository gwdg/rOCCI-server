require 'ipaddr'

module Backends
  module Opennebula
    module Constants
      module Securitygroup
        # Attribute mapping hash for Core
        ATTRIBUTES_CORE = {
          'occi.core.id' => ->(sg) { sg['ID'] },
          'occi.core.title' => ->(sg) { sg['NAME'] },
          'occi.core.summary' => ->(sg) { sg['TEMPLATE/DESCRIPTION'] }
        }.freeze

        # Network masks, SIZE => MASKS
        NETWORK_MASKS = {
          '1'        => '255.255.255.255',
          '254'      => '255.255.255.0',
          '65534'    => '255.255.0.0',
          '16777214' => '255.0.0.0'
        }.freeze

        # Helper for IP conversion, only A, B, C networks are supported
        IP_CONVERT = lambda do |rule|
          return unless NETWORK_MASKS.key?(rule['SIZE'])
          address = IPAddr.new(rule['IP']).mask(NETWORK_MASKS[rule['SIZE']])
          "#{address}/#{address.cidr_mask}"
        end

        # Attribute mapping hash for Infra
        ATTRIBUTES_INFRA = {
          'occi.securitygroup.state' => ->(_sg) { 'active' },
          'occi.securitygroup.rules' => lambda do |sg|
            rules = []
            sg.each('TEMPLATE/RULE') do |rule|
              rl = {
                type: rule['RULE_TYPE'].downcase,
                protocol: rule['PROTOCOL'].downcase,
                range: rule['IP'] ? IP_CONVERT.call(rule) : '0.0.0.0/32',
                port: rule['RANGE'] ? rule['RANGE'] : nil
              }
              rl.delete_if { |_, v| v.blank? }
              rules << rl
            end
            rules
          end
        }.freeze

        # All transferable attributes
        TRANSFERABLE_ATTRIBUTES = [ATTRIBUTES_CORE, ATTRIBUTES_INFRA].freeze
      end
    end
  end
end
