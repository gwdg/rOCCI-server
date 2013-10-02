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
# Description: CloudStack Backend
# Author(s): Isaac Chiang
##############################################################################

module OCCI
  module Backend
    class CloudStack
      module Network

        def network_register_all_instances(client)
          backend_network_objects = client.list_networks 'listall' => true

          if backend_network_objects['network']
            backend_network_objects['network'].each do |network|
              backend_vlan_objects = client.list_vlan_ip_ranges 'networkid' => "#{network['id']}"
              # FIXME: Possible not work in advance zone here
              network_parse_backend_object client, network, backend_vlan_objects['vlaniprange'].first
            end
          end
        end

        def network_parse_backend_object(client, backend_object, vlan)
          network_kind    = @model.get_by_id("http://schemas.ogf.org/occi/infrastructure#network")
          network         = OCCI::Core::Resource.new(network_kind.type_identifier)
          network.id      = backend_object['id']
          network.title   = backend_object['name']
          network.summary = backend_object['displaytext']

          network.attributes.occi!.network!.address = (IPAddr.new(vlan['gateway']) & IPAddr.new(vlan['netmask'])).to_s + 
                                                      "/#{IPAddr.new(vlan['netmask']).to_i.to_s(2).count("1")}"
          network.attributes.occi!.network!.gateway = vlan['gateway']
          network.attributes.occi!.network!.vlan = vlan['vlan'] if vlan['vlan'] && vlan['vlan'] != "untagged"

          network.attributes.org!.apache!.cloudstack!.network!.id = backend_object['id']
          network.attributes.org!.apache!.cloudstack!.network!.broadcastdomaintype = backend_object['broadcastdomaintype'] if backend_object['broadcastdomaintype']
          network.attributes.org!.apache!.cloudstack!.network!.traffictype = backend_object['traffictype'] if backend_object['traffictype']
          network.attributes.org!.apache!.cloudstack!.network!.zoneid = backend_object['zoneid'] if backend_object['zoneid']
          network.attributes.org!.apache!.cloudstack!.network!.zonename = backend_object['zonename'] if backend_object['zonename']
          network.attributes.org!.apache!.cloudstack!.network!.networkofferingid = backend_object['networkofferingid'] if backend_object['networkofferingid']
          network.attributes.org!.apache!.cloudstack!.network!.networkofferingname = backend_object['networkofferingname'] if backend_object['networkofferingname']
          network.attributes.org!.apache!.cloudstack!.network!.networkofferingdisplaytext = backend_object['networkofferingdisplaytext'] if backend_object['networkofferingdisplaytext']
          network.attributes.org!.apache!.cloudstack!.network!.networkofferingavailability = backend_object['networkofferingavailability'] if backend_object['networkofferingavailability']
          network.attributes.org!.apache!.cloudstack!.network!.issystem = backend_object['issystem'] if backend_object['issystem']
          network.attributes.org!.apache!.cloudstack!.network!.state = backend_object['state'] if backend_object['state']
          network.attributes.org!.apache!.cloudstack!.network!.related = backend_object['related'] if backend_object['related']
          network.attributes.org!.apache!.cloudstack!.network!.type = backend_object['type'] if backend_object['type']
          network.attributes.org!.apache!.cloudstack!.network!.acltype = backend_object['acltype'] if backend_object['acltype']
          network.attributes.org!.apache!.cloudstack!.network!.subdomainaccess = backend_object['subdomainaccess'] if backend_object['subdomainaccess']
          network.attributes.org!.apache!.cloudstack!.network!.domainid = backend_object['domainid'] if backend_object['domainid']
          network.attributes.org!.apache!.cloudstack!.network!.domain = backend_object['domain'] if backend_object['domain']
          network.attributes.org!.apache!.cloudstack!.network!.networkdomain = backend_object['networkdomain'] if backend_object['networkdomain']
          network.attributes.org!.apache!.cloudstack!.network!.physicalnetworkid = backend_object['physicalnetworkid'] if backend_object['physicalnetworkid']
          network.attributes.org!.apache!.cloudstack!.network!.restartrequired = backend_object['restartrequired'] if backend_object['restartrequired']
          network.attributes.org!.apache!.cloudstack!.network!.restartrequired = backend_object['restartrequired'] if backend_object['restartrequired']
          network.attributes.org!.apache!.cloudstack!.network!.specifyipranges = backend_object['specifyipranges'] if backend_object['specifyipranges']
          network.attributes.org!.apache!.cloudstack!.network!.canusefordeploy = backend_object['canusefordeploy'] if backend_object['canusefordeploy']
          network.attributes.org!.apache!.cloudstack!.network!.ispersistent = backend_object['ispersistent'] if backend_object['ispersistent']
          
          if backend_object['service']
            # FIXME: capability here
            backend_object['service'].each do |provider|
              network.attributes.org!.apache!.cloudstack!.network!.service!["#{provider['name']}"] = true if provider['name']
            end
          end

          network.attributes.org!.apache!.cloudstack!.network!.vlan!.id = vlan['id'] if vlan['id']
          network.attributes.org!.apache!.cloudstack!.network!.vlan!.forvirtualnetwork = vlan['forvirtualnetwork'] if vlan['forvirtualnetwork']
          network.attributes.org!.apache!.cloudstack!.network!.vlan!.podid = vlan['podid'] if vlan['podid']
          network.attributes.org!.apache!.cloudstack!.network!.vlan!.podname = vlan['podname'] if vlan['podname']
          network.attributes.org!.apache!.cloudstack!.network!.vlan!.startip = vlan['startip'] if vlan['startip']
          network.attributes.org!.apache!.cloudstack!.network!.vlan!.endip = vlan['endip'] if vlan['endip']

          network.check @model

          network_set_state backend_object, network

          network_kind.entities << network unless network_kind.entities.select {|entity| entity.id == network.id}.any?
        end

        def network_set_state(backend_object, network)
          network.attributes.occi!.network!.state = "active"
        end

        def network_deploy(client, network)
          # Not implemented in CloudStack with basic zone
          OCCI::Log.debug "Not yet implemented"
        end

        def network_delete(client, network)
          OCCI::Log.debug "Not yet implemented"
        end
      end
    end
  end
end
