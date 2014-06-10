module Backends
  module Opennebula
    module Helpers
      module NetworkParseHelper
        def network_parse_backend_obj(backend_network)
          network = Occi::Infrastructure::Network.new

          # include some basic mixins
          network.mixins << 'http://schemas.ogf.org/occi/infrastructure/network#ipnetwork'
          network.mixins << 'http://opennebula.org/occi/infrastructure#network'

          # include mixins stored in ON's VN template
          unless backend_network['TEMPLATE/OCCI_NETWORK_MIXINS'].blank?
            backend_network_mixins = backend_network['TEMPLATE/OCCI_NETWORK_MIXINS'].split(' ')
            backend_network_mixins.each do |mixin|
              network.mixins << mixin unless mixin.blank?
            end
          end

          # include basic OCCI attributes
          basic_attrs = network_parse_basic_attrs(backend_network)
          network.attributes.merge! basic_attrs

          # include ONE-specific attributes
          one_attrs = network_parse_one_attrs(backend_network)
          network.attributes.merge! one_attrs

          # include state information and available actions
          result = network_parse_state(backend_network)
          network.state = result.state
          result.actions.each { |a| network.actions << a }

          network
        end

        def network_parse_basic_attrs(backend_network)
          basic_attrs = Occi::Core::Attributes.new

          basic_attrs['occi.core.id']    = backend_network['ID']
          basic_attrs['occi.core.title'] = backend_network['NAME'] if backend_network['NAME']
          basic_attrs['occi.core.summary'] = backend_network['TEMPLATE/DESCRIPTION'] unless backend_network['TEMPLATE/DESCRIPTION'].blank?

          basic_attrs['occi.network.gateway'] = backend_network['TEMPLATE/GATEWAY'] if backend_network['TEMPLATE/GATEWAY']
          basic_attrs['occi.network.vlan'] = backend_network['VLAN_ID'].to_i unless backend_network['VLAN_ID'].blank?

          if backend_network.type_str == 'RANGED'
            basic_attrs['occi.network.allocation'] = 'dynamic'
            basic_attrs['occi.network.address'] = calculate_cidr(backend_network)
          else
            basic_attrs['occi.network.allocation'] = 'static'
          end

          basic_attrs
        end

        def network_parse_one_attrs(backend_network)
          one_attrs = Occi::Core::Attributes.new

          one_attrs['org.opennebula.network.id'] = backend_network['ID']

          if backend_network['VLAN'].blank? || backend_network['VLAN'].to_i == 0
            one_attrs['org.opennebula.network.vlan'] = 'NO'
          else
            one_attrs['org.opennebula.network.vlan'] = 'YES'
          end

          one_attrs['org.opennebula.network.phydev'] = backend_network['PHYDEV'] unless backend_network['PHYDEV'].blank?
          one_attrs['org.opennebula.network.bridge'] = backend_network['BRIDGE'] unless backend_network['BRIDGE'].blank?

          unless backend_network['RANGE'].blank?
            one_attrs['org.opennebula.network.ip_start'] = backend_network['RANGE/IP_START'] if backend_network['RANGE/IP_START']
            one_attrs['org.opennebula.network.ip_end'] = backend_network['RANGE/IP_END'] if backend_network['RANGE/IP_END']
          end

          one_attrs
        end

        def network_parse_state(backend_network)
          result = Hashie::Mash.new

          # ON doesn't implement actions on networks
          result.actions = []
          result.state = 'active'

          result
        end

        def calculate_cidr(backend_network)
          return nil unless backend_network && backend_network['TEMPLATE/NETWORK_ADDRESS']
          return nil if backend_network['TEMPLATE/NETWORK_ADDRESS'].blank?

          if backend_network['TEMPLATE/NETWORK_ADDRESS'].include? '/'
            # already is in CIDR notation
            backend_network['TEMPLATE/NETWORK_ADDRESS']
          elsif backend_network['TEMPLATE/NETWORK_MASK']
            # calculate CIDR from mask
            calculate_cidr_from_mask(backend_network)
          elsif backend_network['TEMPLATE/NETWORK_SIZE']
            # calculate CIDR from network size
            calculate_cidr_from_size(backend_network)
          else
            # no idea what to do
            nil
          end
        end
        private :calculate_cidr

        def calculate_cidr_from_mask(backend_network)
          if backend_network['TEMPLATE/NETWORK_MASK'].include?('.')
            cidr = IPAddr.new(backend_network['TEMPLATE/NETWORK_MASK']).to_i.to_s(2).count('1')
            "#{backend_network['TEMPLATE/NETWORK_ADDRESS']}/#{cidr}"
          else
            "#{backend_network['TEMPLATE/NETWORK_ADDRESS']}/#{backend_network['TEMPLATE/NETWORK_MASK']}"
          end
        end
        private :calculate_cidr_from_mask

        def calculate_cidr_from_size(backend_network)
          case backend_network['TEMPLATE/NETWORK_SIZE']
          when 'A'
            "#{backend_network['TEMPLATE/NETWORK_ADDRESS']}/8"
          when 'B'
            "#{backend_network['TEMPLATE/NETWORK_ADDRESS']}/16"
          when 'C', 254, '254'
            "#{backend_network['TEMPLATE/NETWORK_ADDRESS']}/24"
          else
            nil
          end
        end
        private :calculate_cidr_from_size
      end
    end
  end
end
