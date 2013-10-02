module OCCI
  module Backend
    class CloudStack
      module Compute
        def compute_register_all_instances(client)
          # FIXME: Fix the argument
          backend_instance_objects = client.list_virtual_machines 'listall'=>'true'

          if backend_instance_objects['virtualmachine']
            backend_instance_objects['virtualmachine'].each do |instance|
              compute_parse_backend_instances client, instance unless instance['state'] == 'Destroyed'
            end
          end
        end

        def compute_parse_backend_instances(client, backend_instance)
          compute_kind = @model.get_by_id 'http://schemas.ogf.org/occi/infrastructure#compute'
          id = backend_instance['id']

          compute = OCCI::Core::Resource.new(compute_kind.type_identifier)

          compute.id = id
          compute.title = backend_instance['name']

          # FIXME: Fix occi core model attributes here
          compute.attributes.occi!.compute!.cores  = backend_instance['cpunumber'].to_i if backend_instance['cpunumber']
          compute.attributes.occi!.compute!.memory = backend_instance['memory'].to_f/1000 if backend_instance['memory']
          
          compute.attributes.org!.apache!.cloudstack!.compute!.account   = backend_instance['account'] if backend_instance['account']
          compute.attributes.org!.apache!.cloudstack!.compute!.domain    = backend_instance['domain'] if backend_instance['domain']
          compute.attributes.org!.apache!.cloudstack!.compute!.cpunumber = backend_instance['cpunumber'] if backend_instance['cpunumber']
          compute.attributes.org!.apache!.cloudstack!.compute!.cpuspeed  = backend_instance['cpuspeed'] if backend_instance['cpuspeed']
          compute.attributes.org!.apache!.cloudstack!.compute!.cpuused   = backend_instance['cpuused'] if backend_instance['cpuused']
          compute.attributes.org!.apache!.cloudstack!.compute!.memory    = backend_instance['memory'] if backend_instance['memory']
          compute.attributes.org!.apache!.cloudstack!.compute!.haenable  = backend_instance['passwordenabled'] if backend_instance['passwordenabled']
          compute.attributes.org!.apache!.cloudstack!.compute!.state     = backend_instance['state'] if backend_instance['state']

          compute.mixins << @model.get_by_id(self.attributes.info.rocci.backend.cloudstack.scheme + "/occi/infrastructure/os_tpl##{backend_instance['templateid']}").as_json

          compute.mixins << @model.get_by_id(self.attributes.info.rocci.backend.cloudstack.scheme + "/occi/infrastructure/resource_tpl##{backend_instance['serviceofferingid']}").as_json

          compute.mixins << @model.get_by_id(self.attributes.info.rocci.backend.cloudstack.scheme + "/occi/infrastructure/available_zone##{backend_instance['zoneid']}").as_json

          # compute.mixins << client.list_templates('templatefilter'=>'featured', 'id'=>"#{backend_instance['templateid']}").reject!{ |k| k == 'count'  } if backend_instance['templateid']

          # compute.mixins << client.list_zones('id'=>"#{backend_instance['zoneid']}").reject!{ |k| k == 'count'  } if backend_instance['zoneid']

          compute.mixins.uniq!

          compute.check @model

          compute_parse_storage_links client, compute, backend_instance

          compute_parse_network_links client, compute, backend_instance

          compute_set_state backend_instance, compute

          compute_kind.entities << compute unless compute_kind.entities.select { |entity| entity.id == compute.id }.any?
        end

        def compute_set_state(backend_instance, compute)
          OCCI::Log.debug("current VM state is: #{backend_instance['state']}")
          case backend_instance['state']
          when 'Running' then
            compute.attributes.occi!.compute!.state = "active"
            # compute.attributes.org!.apache!.cloudstack!.compute!.state = backend_instance['state']
            compute.actions                         = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#stop http://schemas.ogf.org/occi/infrastructure/compute/action#restart|
          when 'Stopped'
            compute.attributes.occi!.compute!.state = "inactive"
            # compute.attributes.org!.apache!.cloudstack!.compute!.state = backend_instance['state']
            compute.actions                         = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#start|
          else
          end
        end

        def compute_deploy(client, compute)
          OCCI::Log.debug "Deploying CloudStack instance : #{compute.inspect}"

          os_tpl = compute.mixins.select { |mixin|
            OCCI::Log.debug "Compute deploy found mixin: #{mixin}"
            if mixin.kind_of? String
              mixin = @model.get_by_id(mixin)
            end

            mixin.related_to? "http://schemas.ogf.org/occi/infrastructure#os_tpl" if mixin
          }.compact.first

          resource_tpl = compute.mixins.select { |mixin|
            OCCI::Log.debug "Compute deploy found mixin: #{mixin}"
            if mixin.kind_of? String
              mixin = @model.get_by_id(mixin)
            end

            mixin.related_to? "http://schemas.ogf.org/occi/infrastructure#resource_tpl" if mixin
          }.compact.first

          available_zone = compute.mixins.select { |mixin|
            OCCI::Log.debug "Compute deploy found mixin: #{mixin}"
            if mixin.kind_of? String
              mixin = @model.get_by_id(mixin)
            end

            mixin.related_to? "http://schemas.ogf.org/occi/infrastructure#available_zone" if mixin
          }.compact.first

          available_zone ||= @default_available_zone
          resource_tpl   ||= @default_compute_offering
          os_tpl         ||= @default_os_template

          available_zone = @model.get_by_id available_zone
          resource_tpl   = @model.get_by_id resource_tpl
          os_tpl         = @model.get_by_id os_tpl

          async_job = client.deploy_virtual_machine 'serviceofferingid' => "#{resource_tpl.term}",
                                                    'templateid'        => "#{os_tpl.term}",
                                                    'zoneid'            => "#{available_zone.term}"

          result = query_async_result client, async_job['jobid']

          OCCI::Log.debug "Return code from CloudStack #{result['jobresultcode']}" if result['jobresultcode']

          OCCI::Log.debug "OCCI Compute resource #{result['virtualmachine']}"

          compute_set_state result['virtualmachine'], compute

          # compute_parse_storage_links client, compute, result['virtualmachine']

          # compute_parse_network_links client, compute, result['virtualmachine']

          OCCI::Log.debug "CloudStack automatically triggers action start for Virtual Machines"

          OCCI::Log.debug "Changing state to started"
        end

        def compute_update_state(client, compute)
          OCCI::Log.debug "Updating CloudStack instance status."

          backend_instance = get_backend_instance client, compute
          
          compute_set_state result['virtualmachine'], compute
        end

        def compute_delete(client, compute)
          OCCI::Log.debug "Deleting CloudStack instance."
          backend_instance = get_backend_instance client, compute

          async_job = client.destroy_virtual_machine 'id' => "#{backend_instance['id']}"

          result = query_async_result client, async_job['jobid']

          compute_set_state result['virtualmachine'], compute

          OCCI::Log.debug "Changing state to destroyed"
        end

        def compute_start(client, compute, parameters)
          OCCI::Log.debug "Starting CloudStack instance."

          backend_instance = get_backend_instance client, compute

          async_job = client.start_virtual_machine 'id' => "#{backend_instance['id']}"

          result = query_async_result client, async_job['jobid']

          compute_set_state result['virtualmachine'], compute

          OCCI::Log.debug "Changing state to Running"
        end

        def compute_stop(client, compute, parameters)
          OCCI::Log.debug "Stoping CloudStack instance."
          backend_instance = get_backend_instance client, compute
        
          async_job = client.stop_virtual_machine 'id' => "#{backend_instance['id']}"

          result = query_async_result client, async_job['jobid']

          compute_set_state result['virtualmachine'], compute

          OCCI::Log.debug "Changing state to Stopped"
        end

        def compute_restart(client, compute, parameters)
          OCCI::Log.debug "Restarting CloudStack instance."
          backend_instance = get_backend_instance client, compute

          async_job = client.reboot_virtual_machine 'id' => "#{backend_instance['id']}"

          result = query_async_result client, async_job['jobid']

          compute_set_state result['virtualmachine'], compute

          OCCI::Log.debug "Changing state to Running"
        end

        def get_backend_instance(client, compute)
          backend_instance = client.list_virtual_machines 'id' => "#{compute.attributes.occi.core.id}"

          raise OCCI::BackendError, "No backend instance be found" if !backend_instance

          backend_instance['virtualmachine'].first
        end

        def compute_parse_storage_links(client, compute, backend_instance)
          storage_kind     = @model.get_by_id('http://schemas.ogf.org/occi/infrastructure#storage')
          storagelink_kind = @model.get_by_id('http://schemas.ogf.org/occi/infrastructure#storagelink')

          associated_volumes = client.list_volumes 'virtualmachineid' => "#{compute.attributes.occi.core.id}",
                                                   'type'             => 'DATADISK'

          if associated_volumes['volume']
            associated_volumes['volume'].each_with_index do |volume, idx|
              target     = storage_kind.entities.select { |entity| entity.id == "#{volume['id']}" }.first
              link       = OCCI::Core::Link.new(storagelink_kind.type_identifier)
              link.id    = "#{SecureRandom.uuid}"
              link.mixins << 'http://schemas.ogf.org/occi/infrastructure#storagelink'
              link.target = target.location
              link.rel    = target.kind
              link.title  = target.title unless target.title.nil?
              link.source = compute.location
              link.attributes.occi!.storagelink!.state = "active"
              link.check @model
              compute.links << link
              storagelink_kind.entities << link
            end
          end
        end

        def compute_parse_network_links(client, compute, backend_object)
          network_kind          = @model.get_by_id('http://schemas.ogf.org/occi/infrastructure#network')
          networkinterface_kind = @model.get_by_id('http://schemas.ogf.org/occi/infrastructure#networkinterface')

          associated_networks = client.list_networks 'virtualmachineid' => "#{compute.attributes.occi.core.id}"

          if associated_networks['network']
            associated_networks['network'].each_with_index do |network, idx|
              target = network_kind.entities.select { |entity| entity.id == "#{network['id']}" }.first
              link        = OCCI::Core::Link.new(network_kind.type_identifier)
              link.id     = "#{SecureRandom.uuid}"
              link.target = target.location
              link.rel    = target.kind
              link.title  = target.title unless target.title.nil?
              link.source = compute.location

              link.mixins << 'http://schemas.ogf.org/occi/infrastructure/networkinterface#ipnetworkinterface'
              link.mixins << 'http://schemas.ogf.org/occi/infrastructure#networkinterface'
              link.mixins.uniq!

              nic = backend_object['nic'].first
              link.attributes.occi!.networkinterface!.address = nic['ipaddress'] if nic['ipaddress']
              link.attributes.occi!.networkinterface!.mac = nic['macaddress'] if nic['macaddress']
              link.attributes.occi!.networkinterface!.interface = nic['id'] if nic['id']
              link.attributes.occi!.networkinterface!.state = "active"

              link.check @model
              compute.links << link
              networkinterface_kind.entities << link
            end
          end
        end
      end
    end
  end
end
