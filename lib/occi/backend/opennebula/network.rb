##############################################################################
#  Copyright 2011 Service Computing group, TU Dortmund
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
##############################################################################

##############################################################################
# Description: OpenNebula Backend
# Author(s): Hayati Bice, Florian Feldhaus, Piotr Kasprzak
##############################################################################

require 'occi/log'              
require 'erubis'
require 'ipaddr'

module OCCI
  module Backend
    class OpenNebula

      # ---------------------------------------------------------------------------------------------------------------------
      module Network

        # location cache mapping OCCI locations to OpenNebula VM IDs
        @@location_cache = {}

        TEMPLATENETWORKRAWFILE = 'network.erb'

        # ---------------------------------------------------------------------------------------------------------------------       
        #        private
        # ---------------------------------------------------------------------------------------------------------------------

        # ---------------------------------------------------------------------------------------------------------------------     
        def network_parse_backend_object(client, backend_object)

          # get information on storage object from OpenNebula backend
          backend_object.info

          network_kind = @model.get_by_id("http://schemas.ogf.org/occi/infrastructure#network")

          id = backend_object['TEMPLATE/OCCI_ID']
          id ||= self.generate_occi_id(network_kind, backend_object.id.to_s)

          @@location_cache[id] = backend_object.id.to_s

          network = OCCI::Core::Resource.new(network_kind.type_identifier)

          network.mixins << 'http://opennebula.org/occi/infrastructure#network'
          network.mixins << 'http://schemas.ogf.org/occi/infrastructure#ipnetwork'
          backend_object.each 'TEMPLATE/OCCI_MIXIN' do |mixin|
            network.mixins << mixin.text
          end
          network.mixins.uniq!

          network.id = id
          network.title = backend_object['NAME'] if backend_object['NAME']
          network.summary = backend_object['TEMPLATE/DESCRIPTION'] if backend_object['TEMPLATE/DESCRIPTION']

          network.attributes.occi!.network!.address = backend_object['TEMPLATE/NETWORK_ADDRESS'] if backend_object['TEMPLATE/NETWORK_ADDRESS']
          network.attributes.occi!.network!.gateway = backend_object['TEMPLATE/GATEWAY'] if backend_object['TEMPLATE/GATEWAY']
          network.attributes.occi!.network!.vlan = backend_object['TEMPLATE/VLAN_ID'] if backend_object['TEMPLATE/VLAN_ID']
          network.attributes.occi!.network!.allocation = "static" if backend_object['TYPE'].to_i == 1
          network.attributes.occi!.network!.allocation = "dynamic" if backend_object['TYPE'].to_i == 0
          if backend_object['TEMPLATE/TYPE']
            network.attributes.occi!.network!.allocation = "dynamic" if backend_object['TEMPLATE/TYPE'].downcase == "ranged"
            network.attributes.occi!.network!.allocation = "static" if backend_object['TEMPLATE/TYPE'].downcase == "fixed"
          end
          if backend_object['NETWORK_ADDRESS']
            if backend_object['NETWORK_ADDRESS'].include? '/'
              network.attributes.occi!.network!.address = backend_object['NETWORK_ADDRESS']
            else
              cidr = case backend_object['NETWORK_SIZE']
                       when 'A'
                         8
                       when 'B'
                         16
                       when 'C'
                         24
                       when /\d/
                         (32-(Math.log(backend_object['NETWORK_SIZE'])/Math.log(2)).ceil).to_s
                       else
                         0
                     end
              cidr = IPAddr.new(backend_object['NETWORK_MASK']).to_i.to_s(2).count("1") if  backend_object['NETWORK_MASK']

              network.attributes.occi!.network!.address = backend_object['NETWORK_ADDRESS'] + '/' + cidr
            end
          end

          network.attributes.org!.opennebula!.network!.id = backend_object['ID'] if backend_object['ID']
          network.attributes.org!.opennebula!.network!.vlan = backend_object['TEMPLATE/VLAN'] if backend_object['TEMPLATE/VLAN']
          network.attributes.org!.opennebula!.network!.phydev = backend_object['TEMPLATE/PHYDEV'] if backend_object['TEMPLATE/PHYDEV']
          network.attributes.org!.opennebula!.network!.bridge = backend_object['TEMPLATE/BRIDGE'] if backend_object['TEMPLATE/BRIDGE']

          network.attributes.org!.opennebula!.network!.ip_start = backend_object['TEMPLATE/IP_START'] if backend_object['TEMPLATE/IP_START']
          network.attributes.org!.opennebula!.network!.ip_end = backend_object['TEMPLATE/IP_END'] if backend_object['TEMPLATE/IP_END']

          network.check(@model)

          network_set_state(backend_object, network)

          network_kind.entities << network unless network_kind.entities.select {|entity| entity.id == network.id}.any?
        end

        # ---------------------------------------------------------------------------------------------------------------------
        public
        # ---------------------------------------------------------------------------------------------------------------------

        # ---------------------------------------------------------------------------------------------------------------------     
        def network_deploy(client, network)

          backend_object = VirtualNetwork.new(VirtualNetwork.build_xml(), client)

          template_location = File.dirname(__FILE__) + '/../../../../etc/backend/opennebula/one_templates/' + TEMPLATENETWORKRAWFILE
          template = Erubis::Eruby.new(File.read(template_location)).evaluate(:network => network)

          OCCI::Log.debug("Parsed template #{template}")
          rc = backend_object.allocate(template)
          check_rc(rc)

          backend_object.info
          network.id ||= self.generate_occi_id(@model.get_by_id(network.kind), backend_object['ID'].to_s)

          network_set_state(backend_object, network)

          OCCI::Log.debug("OpenNebula ID of virtual network: #{@@location_cache[network.id]}")
        end

        # ---------------------------------------------------------------------------------------------------------------------
        def network_set_state(backend_object, network)
          network.attributes.occi!.network!.state = "active"
        end

        # ---------------------------------------------------------------------------------------------------------------------     
        def network_delete(client, network)
          backend_object = VirtualNetwork.new(VirtualNetwork.build_xml(@@location_cache[network.id]), client)
          rc = backend_object.delete
          check_rc(rc)
        end

        # ---------------------------------------------------------------------------------------------------------------------     
        def network_register_all_instances(client)
          occi_objects = []
          backend_object_pool=VirtualNetworkPool.new(client)
          backend_object_pool.info_all
          backend_object_pool.each { |backend_object| network_parse_backend_object(client, backend_object) }
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # STORAGE ACTIONS
        # ---------------------------------------------------------------------------------------------------------------------

        # ---------------------------------------------------------------------------------------------------------------------
        def network_action_dummy(client, network, parameters)
        end

        # ---------------------------------------------------------------------------------------------------------------------
        def network_up(client, network, parameters)
          backend_object = VirtualNetwork.new(VirtualNetwork.build_xml(@@location_cache[network.id]), client)
          # not implemented in OpenNebula
        end

        # ---------------------------------------------------------------------------------------------------------------------
        def network_down(client, network, parameters)
          backend_object = VirtualNetwork.new(VirtualNetwork.build_xml(@@location_cache[network.id]), client)
          # not implemented in OpenNebula
        end

      end

    end
  end
end
