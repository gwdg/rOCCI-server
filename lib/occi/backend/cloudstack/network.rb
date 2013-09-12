module OCCI
  module Backend
    class CloudStack
      module Network

        def network_parse_backend_object(client, backend_object)
          # backend_network_objects = client.list_networks 'listall' => 'true'
          # backend_network_objects['network'].each do |net|

          #   network_kind = @model.get_by_id("http://schemas.ogf.org/occi/infrastructure#network")
          #   id = net['id'].to_s

          #   network = OCCI::Core::Resource.new(network_kind.type_identifier)

          #   network.mixins << 'http://opennebula.org/occi/infrastructure#network'
          #   network.mixins << 'http://schemas.ogf.org/occi/infrastructure#ipnetwork'

          #   network.title = net['name']
          # end
        end
      end
    end
  end
end
