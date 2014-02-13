module Backends
  module Opennebula
    module Helpers
      module NetworkParseHelper
        def network_parse_backend_obj(backend_network)
          network = Occi::Infrastructure::Network.new

          # include some basic mixins
          network.mixins << 'http://opennebula.org/occi/infrastructure#network'

          # include mixins stored in ON's VN template
          unless backend_network['TEMPLATE/OCCI_NETWORK_MIXINS'].blank?
            backend_network_mixins = backend_network['TEMPLATE/OCCI_NETWORK_MIXINS'].split(' ')
            backend_network_mixins.each do |mixin|
              network.mixins << mixin unless mixin.blank?
            end
          end

          network.id    = backend_network['ID']
          network.title = backend_network['NAME'] if backend_network['NAME']
          network.summary = backend_network['TEMPLATE/DESCRIPTION'] if backend_network['TEMPLATE/DESCRIPTION']

          network.gateway = backend_network['TEMPLATE/GATEWAY'] if backend_network['TEMPLATE/GATEWAY']
          network.vlan = backend_network['VLAN_ID'].to_i if backend_network['VLAN_ID']

          unless backend_network['TEMPLATE/NETWORK_ADDRESS'].blank?
            network.allocation = 'dynamic'

            if backend_network['TEMPLATE/NETWORK_ADDRESS'].include? '/'
              network.address = backend_network['TEMPLATE/NETWORK_ADDRESS']
            else
              unless backend_network['TEMPLATE/NETWORK_MASK'].blank?
                if backend_network['TEMPLATE/NETWORK_MASK'].include?('.')
                  cidr = IPAddr.new(backend_network['TEMPLATE/NETWORK_MASK']).to_i.to_s(2).count('1')
                  network.address = "#{backend_network['TEMPLATE/NETWORK_ADDRESS']}/#{cidr}"
                else
                  network.address = "#{backend_network['TEMPLATE/NETWORK_ADDRESS']}/#{backend_network['TEMPLATE/NETWORK_MASK']}"
                end
              end
            end
          else
            network.allocation = 'static'
          end

          network.attributes['org.opennebula.network.id'] = backend_network['ID']

          if backend_network['VLAN'].blank? || backend_network['VLAN'].to_i == 0
            network.attributes['org.opennebula.network.vlan'] = 'NO'
          else
            network.attributes['org.opennebula.network.vlan'] = 'YES'
          end

          network.attributes['org.opennebula.network.phydev'] = backend_network['PHYDEV'] unless backend_network['PHYDEV'].blank?
          network.attributes['org.opennebula.network.bridge'] = backend_network['BRIDGE'] unless backend_network['BRIDGE'].blank?

          if backend_network['RANGE']
            network.attributes['org.opennebula.network.ip_start'] = backend_network['RANGE/IP_START'] if backend_network['RANGE/IP_START']
            network.attributes['org.opennebula.network.ip_end'] = backend_network['RANGE/IP_END'] if backend_network['RANGE/IP_END']
          end

          result = network_parse_set_state(backend_network)
          network.state = result.state
          result.actions.each { |a| network.actions << a }

          network
        end

        def network_parse_set_state(backend_network)
          result = Hashie::Mash.new

          # ON doesn't implement actions on networks
          result.actions = []
          result.state = 'active'

          result
        end
      end
    end
  end
end
