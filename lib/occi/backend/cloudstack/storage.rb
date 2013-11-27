module OCCI
  module Backend
    class CloudStack
      module Storage
        def storage_register_all_instances(client)
          backend_storage_objects = client.list_volumes 'listall' => true,
                                                        'type' => 'DATADISK'

          if backend_storage_objects['volume']
            backend_storage_objects['volume'].each do |storage|
              storage_parse_backend_object client, storage
            end
          end
        end

        def storage_parse_backend_object(client, backend_storage)
          storage_kind    = @model.get_by_id("http://schemas.ogf.org/occi/infrastructure#storage")
          storage         = OCCI::Core::Resource.new(storage_kind.type_identifier)
          storage.id      = backend_storage['id']
          storage.title   = backend_storage['name']
          storage.summary = backend_storage['name']

          storage.attributes.org!.apache!.cloudstack!.storage!.zoneid = backend_storage['zoneid'] if backend_storage['zoneid']
          storage.attributes.org!.apache!.cloudstack!.storage!.zonename = backend_storage['zonename'] if backend_storage['zonename']
          storage.attributes.org!.apache!.cloudstack!.storage!.type = backend_storage['type'] if backend_storage['type']
          storage.attributes.org!.apache!.cloudstack!.storage!.deviceid = backend_storage['deviceid'] if backend_storage['deviceid']
          storage.attributes.org!.apache!.cloudstack!.storage!.virtualmachineid = backend_storage['virtualmachineid'] if backend_storage['virtualmachineid']
          storage.attributes.org!.apache!.cloudstack!.storage!.vmname = backend_storage['vmname'] if backend_storage['vmname']
          storage.attributes.org!.apache!.cloudstack!.storage!.vmstate = backend_storage['vmstate'] if backend_storage['vmstate']
          storage.attributes.org!.apache!.cloudstack!.storage!.size = backend_storage['size'] if backend_storage['size']
          storage.attributes.org!.apache!.cloudstack!.storage!.state = backend_storage['state'] if backend_storage['state']
          storage.attributes.org!.apache!.cloudstack!.storage!.account = backend_storage['account'] if backend_storage['account']
          storage.attributes.org!.apache!.cloudstack!.storage!.domainid = backend_storage['domainid'] if backend_storage['domainid']
          storage.attributes.org!.apache!.cloudstack!.storage!.domain = backend_storage['domain'] if backend_storage['domain']
          storage.attributes.org!.apache!.cloudstack!.storage!.storagetype = backend_storage['storagetype'] if backend_storage['storagetype']
          storage.attributes.org!.apache!.cloudstack!.storage!.hypervisor = backend_storage['hypervisor'] if backend_storage['hypervisor']
          # storage.attributes.org!.apache!.cloudstack!.storage!.diskofferingid = backend_storage['diskofferingid'] if backend_storage['diskofferingid']
          # storage.attributes.org!.apache!.cloudstack!.storage!.diskofferingname = backend_storage['diskofferingname'] if backend_storage['diskofferingname']
          # storage.attributes.org!.apache!.cloudstack!.storage!.diskofferingdisplaytext = backend_storage['diskofferingdisplaytext'] if backend_storage['diskofferingdisplaytext']
          storage.attributes.org!.apache!.cloudstack!.storage!.storage = backend_storage['storage'] if backend_storage['storage']
          storage.attributes.org!.apache!.cloudstack!.storage!.destroyed = backend_storage['destroyed'] if backend_storage['destroyed']
          storage.attributes.org!.apache!.cloudstack!.storage!.isextractable = backend_storage['isextractable'] if backend_storage['isextractable']
          # FIXME: tags attributes
          
          storage.mixins << @model.get_by_id(self.attributes.info.rocci.backend.cloudstack.scheme + "/occi/infrastructure/disk_offering##{backend_storage['diskofferingid']}").as_json

          storage.mixins.uniq!

          storage.check @model
          
          storage_set_state backend_storage, storage

          storage_kind.entities << storage unless storage_kind.entities.select {|entity| entity.id == storage.id}.any?
        end

        def storage_set_state(backend_object, storage)
          OCCI::Log.debug("current data disk state is: #{backend_object['state']}")
          case backend_object['state']
          when 'Ready', 'Allocated' then
            if backend_object['attached']
              storage.attributes.org!.occi!.storage!.state = "attached"
              storage.actions = %w|http://schemas.ogf.org/occi/infrastructure/storage/action#detach|
            else
              storage.attributes.org!.occi!.storage!.state = "ready"
              storage.actions = %w|http://schemas.ogf.org/occi/infrastructure/storage/action#attach|
            end
            storage.actions << "http://schemas.ogf.org/occi/infrastructure/storage/action#snapshot"
          else
            storage.attributes.org!.occi!.storage!.state = "degarded"
          end
        end

        def storage_deploy(client, storage)
          OCCI::Log.debug "Deploying CloudStack data disk : #{storage.inspect}"

          disk_offering = storage.mixins.select { |mixin|
            OCCI::Log.debug "Storage deploy found mixin: #{mixin}"
            if mixin.kind_of? String
              mixin = @model.get_by_id(mixin)
            end

            mixin.related_to? "http://schemas.ogf.org/occi/infrastructure#disk_offering" if mixin
          }.compact.first

          available_zone = storage.mixins.select { |mixin|
            OCCI::Log.debug "Storage deploy found mixin: #{mixin}"
            if mixin.kind_of? String
              mixin = @model.get_by_id(mixin)
            end

            mixin.related_to? "http://schemas.ogf.org/occi/infrastructure#available_zone" if mixin
          }.compact.first

          storage_name = storage.attributes.occi.core.title

          disk_offering  ||= @default_disk_offering
          available_zone ||= @default_available_zone
          storage_name   ||= "#{SecureRandom.uuid}" #generate random name for disk

          disk_offering  = @model.get_by_id disk_offering
          available_zone = @model.get_by_id available_zone

          async_job = client.create_volume "diskofferingid" => "#{disk_offering.term}",
                                           "zoneid"         => "#{available_zone.term}",
                                           "name"           => "#{storage_name}"

          result = query_async_result client, async_job['jobid']

          storage_set_state result['volume'], storage

          OCCI::Log.debug "Changing storage state to ready"
        end

        def get_backend_disk_instance(client, storage)
          backend_disk_instance = client.list_volumes 'id' => "#{storage.attributes.occi.core.id}"

          raise OCCI::BackendError, "No backend instance be found" if !backend_disk_instance

          backend_disk_instance['volume'].first
        end

        def storage_delete(client, storage)
          OCCI::Log.debug("Deleting CloudStack disk instance")
          backend_disk_instance = get_backend_disk_instance client, storage

          result = client.delete_volume 'id' => "#{backend_disk_instance['id']}"

          check_result result

          OCCI::Log.debug "Disk has been removed"
        end

        def storage_attach(client, storage, parameters)
          OCCI::Log.debug "Attaching CloudStack disk instance: #{storage.inspect}"
          compute_id   = parameters['resources'].first['attributes']['occi']['core']['id']
          async_job = client.attach_volume 'id'               => "#{storage.attributes.occi.core.id}",
                                           'virtualmachineid' => "#{compute_id}"

          result = query_async_result client, async_job['jobid']

          storage_set_state result['volume'], storage

          OCCI::Log.debug "Changing storage state"
        end

        def storage_detach(client, storage, parameters)
          OCCI::Log.debug "Detaching CloudStack disk instance: #{storage.inspect}"
          async_job = client.detach_volume 'id' => "#{storage.attributes.occi.core.id}"

          result = query_async_result client, async_job['jobid']

          storage_set_state result['volume'], storage

          OCCI::Log.debug "Changing storage state"
        end

        def storage_snapshot(client, storage, parameters)
          OCCI::Log.debug "Not supported yet"
        end
      end
    end
  end
end
