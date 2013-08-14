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

module OCCI
  module Backend
    class OpenNebula

      SSH_REGEXP = /^(command=.+\s)?((?:ssh\-|ecds)[\w-]+\s.+)$/
      BASE64_REGEXP = /^[A-Za-z0-9+\/]+={0,2}$/

      # ---------------------------------------------------------------------------------------------------------------------
      module Compute

        # location cache mapping OCCI locations to OpenNebula VM IDs
        @@location_cache = { }

        TEMPLATECOMPUTERAWFILE = 'compute.erb'

        # ---------------------------------------------------------------------------------------------------------------------
        #        private
        # ---------------------------------------------------------------------------------------------------------------------

        # ---------------------------------------------------------------------------------------------------------------------
        # PARSE OPENNEBULA COMPUTE OBJECT
        def compute_parse_backend_object(client, backend_object)

          # get information on compute object from OpenNebula backend
          backend_object.info

          compute_kind = @model.get_by_id("http://schemas.ogf.org/occi/infrastructure#compute")

          id = backend_object['TEMPLATE/OCCI_ID']
          id ||= backend_object['USER_TEMPLATE/OCCI_ID']
          id ||= self.generate_occi_id(compute_kind, backend_object.id.to_s)

          @@location_cache[id] = backend_object.id.to_s

          compute = OCCI::Core::Resource.new(compute_kind.type_identifier)

          compute.mixins << 'http://opennebula.org/occi/infrastructure#compute'
          backend_object.each 'TEMPLATE/OCCI_MIXIN' do |mixin|
            compute.mixins << mixin.text
          end
          backend_object.each 'USER_TEMPLATE/OCCI_MIXIN' do |mixin|
            compute.mixins << mixin.text
          end
          compute.mixins.uniq!

          compute.id    = id
          compute.title = backend_object['NAME'] if backend_object['NAME']
          compute.summary = backend_object['TEMPLATE/DESCRIPTION'] if backend_object['TEMPLATE/DESCRIPTION']
          compute.summary = backend_object['USER_TEMPLATE/DESCRIPTION'] if backend_object['USER_TEMPLATE/DESCRIPTION']

          compute.attributes.occi!.compute!.cores = backend_object['TEMPLATE/VCPU'].to_i if backend_object['TEMPLATE/VCPU']
          compute.attributes.occi!.compute!.architecture = "x64" if backend_object['TEMPLATE/ARCHITECTURE'] == "x86_64"
          compute.attributes.occi!.compute!.architecture = "x86" if backend_object['TEMPLATE/ARCHITECTURE'] == "i686"
          compute.attributes.occi!.compute!.architecture = "x64" if backend_object['USER_TEMPLATE/ARCHITECTURE'] == "x86_64"
          compute.attributes.occi!.compute!.architecture = "x86" if backend_object['USER_TEMPLATE/ARCHITECTURE'] == "i686"
          compute.attributes.occi!.compute!.memory = backend_object['TEMPLATE/MEMORY'].to_f/1000 if backend_object['TEMPLATE/MEMORY']

          compute.attributes.org!.opennebula!.compute!.cpu = backend_object['TEMPLATE/CPU'].to_f if backend_object['TEMPLATE/CPU']
          compute.attributes.org!.opennebula!.compute!.kernel = backend_object['TEMPLATE/KERNEL'] if backend_object['TEMPLATE/KERNEL']
          compute.attributes.org!.opennebula!.compute!.initrd = backend_object['TEMPLATE/INITRD'] if backend_object['TEMPLATE/INITRD']
          compute.attributes.org!.opennebula!.compute!.root = backend_object['TEMPLATE/ROOT'] if backend_object['TEMPLATE/ROOT']
          compute.attributes.org!.opennebula!.compute!.kernel_cmd = backend_object['TEMPLATE/KERNEL_CMD'] if backend_object['TEMPLATE/KERNEL_CMD']
          compute.attributes.org!.opennebula!.compute!.bootloader = backend_object['TEMPLATE/BOOTLOADER'] if backend_object['TEMPLATE/BOOTLOADER']
          compute.attributes.org!.opennebula!.compute!.boot = backend_object['TEMPLATE/BOOT'] if backend_object['TEMPLATE/BOOT']

          compute.check(@model)

          compute_set_state(backend_object, compute)
          compute_parse_links(client, compute, backend_object)

          # register compute resource in entities of compute kind
          compute_kind.entities << compute unless compute_kind.entities.select { |entity| entity.id == compute.id }.any?
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # PARSE OPENNEBULA DEPENDENCIES TO E.G. STORAGE AND NETWORK LINKS
        def compute_parse_links(client, compute, backend_object)
          # create links for all storage instances
          backend_object.each('TEMPLATE/DISK') do |disk|
            offset = 0
            id     = disk['DISK_ID'].to_i
            id = disk['IMAGE_ID'].to_i if disk['IMAGE_ID']
            OCCI::Log.debug("Disk type #{disk['TYPE']}")
            OCCI::Log.debug disk.inspect
            case disk['TYPE'].downcase
            when 'fs', 'swap'
              offset  = 100000 # set an offset for OCCI ID generation to distinguish from Images
              storage = OCCI::Core::Resource.new('http://schemas.ogf.org/occi/infrastructure#storage')
              storage.mixins << 'http://opennebula.org/occi/infrastructure#storage'
              storage.id = disk['STORAGE_OCCI_ID']
              storage.id ||= self.generate_occi_id(@model.get_by_id(storage.kind), (id + offset).to_s)

              storage.attributes.occi!.storage!.size              = disk['SIZE']
              storage.attributes.org!.opennebula!.storage!.fstype = disk['FORMAT'] if disk['FORMAT']
              @model.get_by_id(storage.kind).entities << storage
            else
            end
            OCCI::Log.debug("Storage Backend ID: #{id}")
            storage_kind     = @model.get_by_id('http://schemas.ogf.org/occi/infrastructure#storage')
            storage_id       = disk['STORAGE_OCCI_ID']
            storage_id       ||= self.generate_occi_id(storage_kind, (id + offset).to_s)
            storagelink_kind = @model.get_by_id('http://schemas.ogf.org/occi/infrastructure#storagelink')
            link             = OCCI::Core::Link.new(storagelink_kind.type_identifier)
            link.id          = disk['LINK_OCCI_ID']
            link.id          ||= self.generate_occi_id(storagelink_kind, (id + offset).to_s)
            target           = storage_kind.entities.select { |entity| entity.id == storage_id }.first
            if target.nil?
              one_storage = OpenNebula::Image.new(OpenNebula::Image.build_xml(disk['IMAGE_ID']), client)
              self.storage_parse_backend_object(client, one_storage)
              target = storage_kind.entities.select { |entity| entity.id == storage_id }.first
            end
            link.target = target.location
            link.rel    = target.kind
            link.title  = target.title unless target.title.nil?
            link.source = compute.location
            link.mixins << 'http://opennebula.org/occi/infrastructure#storagelink'
            disk.each 'LINK_OCCI_MIXIN' do |mixin|
              link.mixins << mixin.text
            end
            link.mixins.uniq!
            link.attributes.occi!.storagelink!.deviceid = disk['TARGET'] if disk['TARGET']
            link.attributes.org!.opennebula!.storagelink!.bus = disk['BUS'] if disk['BUS']
            link.attributes.org!.opennebula!.storagelink!.driver = disk['DRIVER'] if disk['TARGET']

            # check link attributes against definition in kind and mixins
            link.check(@model)

            compute.links << link

            storagelink_kind.entities << link
          end

          #create links for all network instances
          backend_object.each('TEMPLATE/NIC') do |nic|
            OCCI::Log.debug("Network Backend ID: #{nic['NETWORK_ID']}")

            networkinterface_kind = @model.get_by_id('http://schemas.ogf.org/occi/infrastructure#networkinterface')
            link                  = OCCI::Core::Link.new(networkinterface_kind.type_identifier)
            link.id               = nic['LINK_OCCI_ID']
            link.id               ||= self.generate_occi_id(networkinterface_kind, nic['NETWORK_ID'].to_s)
            network_kind          = @model.get_by_id('http://schemas.ogf.org/occi/infrastructure#network')
            network_id            = nic['NETWORK_OCCI_ID']
            network_id            ||= self.generate_occi_id(network_kind, nic['NETWORK_ID'].to_s)
            target                = network_kind.entities.select { |entity| entity.id == network_id }.first
            if target.nil?
              one_network = VirtualNetwork.new(VirtualNetwork.build_xml(nic['NETWORK_ID']), client)
              self.network_parse_backend_object(client, one_network)
              target = network_kind.entities.select { |entity| entity.id == network_id }.first
            end
            link.target = target.location
            link.rel    = target.kind
            link.title  = target.title unless target.title.nil?
            link.source = compute.location
            link.mixins << 'http://schemas.ogf.org/occi/infrastructure/networkinterface#ipnetworkinterface'
            link.mixins << 'http://opennebula.org/occi/infrastructure#networkinterface'
            nic.each 'LINK_OCCI_MIXIN' do |mixin|
              link.mixins << mixin.text
            end
            link.mixins.uniq!
            link.attributes.occi!.networkinterface!.address = nic['IP'] if nic['IP']
            link.attributes.occi!.networkinterface!.mac = nic['MAC'] if nic['MAC']
            link.attributes.occi!.networkinterface!.interface = nic['TARGET'] if nic['TARGET']
            link.attributes.org!.opennebula!.networkinterface!.bridge = nic['BRIDGE'] if nic['BRIDGE']
            link.attributes.org!.opennebula!.networkinterface!.script = nic['SCRIPT'] if nic['SCRIPT']
            link.attributes.org!.opennebula!.networkinterface!.white_ports_tcp = nic['WHITE_PORTS_TCP'] if nic['WHITE_PORTS_TCP']
            link.attributes.org!.opennebula!.networkinterface!.black_ports_tcp = nic['BLACK_PORTS_TCP'] if nic['BLACK_PORTS_TCP']
            link.attributes.org!.opennebula!.networkinterface!.white_ports_udp = nic['WHITE_PORTS_UDP'] if nic['WHITE_PORTS_UDP']
            link.attributes.org!.opennebula!.networkinterface!.black_ports_udp = nic['BLACK_PORTS_UDP'] if nic['BLACK_PORTS_UDP ']
            link.attributes.org!.opennebula!.networkinterface!.icmp = nic['ICMP'] if nic['ICMP ']

            # check link attributes against definition in kind and mixins
            link.check(@model)

            compute.links << link

            networkinterface_kind.entities << link
          end
        end

        # ---------------------------------------------------------------------------------------------------------------------
        public
        # ---------------------------------------------------------------------------------------------------------------------

        # ---------------------------------------------------------------------------------------------------------------------
        def compute_deploy(client, compute)

          OCCI::Log.debug "Deploying #{compute.inspect}"

          os_tpl = compute.mixins.select { |mixin|
            OCCI::Log.debug("Compute deploy found mixin: #{mixin}")
            if mixin.kind_of? String
              mixin = @model.get_by_id(mixin)
            end

            mixin.related_to? "http://schemas.ogf.org/occi/infrastructure#os_tpl" if mixin
          }.compact.first

          os_tpl = @model.get_by_id(os_tpl)

          OCCI::Log.debug("Compute deploy OS template: #{os_tpl} #{os_tpl.nil? ? 'No template found!' : os_tpl.title}")

          templates = TemplatePool.new(client)
          templates.info_all

          template = nil
          if os_tpl
            template = templates.select { |template|
              OCCI::Log.debug("Going through ON template #{template['NAME']}")
              template['NAME'] == os_tpl.title
            }.first
          end

          # check context vars
          if compute.attributes.org!.openstack
            if compute.attributes.org!.openstack!.credentials!.publickey!.data
              raise OCCI::BackendError, 'Public key is invalid!' unless SSH_REGEXP.match(compute.attributes.org.openstack.credentials.publickey.data)
            end

            if compute.attributes.org!.openstack!.compute!.user_data
              raise OCCI::BackendError, 'User data contains invalid characters!' unless BASE64_REGEXP.match(compute.attributes.org.openstack.compute.user_data.gsub("\n", ''))
            end
          end

          backend_object = nil
          if template

            if compute.attributes.occi.compute
              vcpu = compute.attributes.occi.compute.cores if compute.attributes.occi.compute.cores
              memory = (compute.attributes.occi.compute.memory.to_f * 1000).to_i if compute.attributes.occi.compute.memory
              architecture = compute.attributes.occi.compute.architecture if compute.attributes.occi.compute.architecture
              cpu = compute.attributes.occi.compute.speed if compute.attributes.occi.compute.speed
            end

            if vcpu
              template.delete_element('TEMPLATE/VCPU')
              template.add_element('TEMPLATE', { "VCPU" => vcpu })
            end

            if memory
              template.delete_element('TEMPLATE/MEMORY')
              template.add_element('TEMPLATE', { "MEMORY" => memory })
            end

            if architecture
              template.delete_element('TEMPLATE/ARCHITECTURE')
              template.add_element('TEMPLATE', { "ARCHITECTURE" => architecture })
            end

            if cpu
              template.delete_element('TEMPLATE/CPU')
              template.add_element('TEMPLATE', { "CPU" => cpu })
            end

            template.add_element('TEMPLATE', "OCCI_ID" => compute.id)

            compute.mixins.each do |mixin|
              template.add_element('TEMPLATE', "OCCI_MIXIN" => mixin)
            end

            if compute.attributes.org!.openstack
              template.add_element('TEMPLATE', "CONTEXT" => '')

              if compute.attributes.org!.openstack!.credentials!.publickey!.data
                template.delete_element('TEMPLATE/CONTEXT/SSH_KEY')
                template.add_element('TEMPLATE/CONTEXT', "SSH_KEY" => compute.attributes.org.openstack.credentials.publickey.data)

                template.delete_element('TEMPLATE/CONTEXT/SSH_PUBLIC_KEY')
                template.add_element('TEMPLATE/CONTEXT', "SSH_PUBLIC_KEY" => compute.attributes.org.openstack.credentials.publickey.data)
              end

              if compute.attributes.org!.openstack!.compute!.user_data
                template.delete_element('TEMPLATE/CONTEXT/USER_DATA')
                template.add_element('TEMPLATE/CONTEXT', "USER_DATA" => compute.attributes.org.openstack.compute.user_data)
              end
            end

            vm_name = ""
            vm_name = compute.attributes.occi.core.title if compute.attributes.occi.core.title

            # remove template-specific values
            template.delete_element('ID')
            template.delete_element('UID')
            template.delete_element('GID')
            template.delete_element('UNAME')
            template.delete_element('GNAME')
            template.delete_element('REGTIME')
            template.delete_element('PERMISSIONS')
            template.delete_element('TEMPLATE/TEMPLATE_ID')

            # set template name
            template.delete_element('TEMPLATE/NAME')
            template.add_element('TEMPLATE', 'NAME' => vm_name || "rOCCIVMGeneric")

            template = template.template_str
            OCCI::Log.debug "Template #{template}"
          else
            template_location = File.dirname(__FILE__) + '/../../../../etc/backend/opennebula/one_templates/' + TEMPLATECOMPUTERAWFILE
            template          = Erubis::Eruby.new(File.read(template_location)).evaluate({ :compute => compute, :model => @model })

            OCCI::Log.debug("Parsed template #{template}")
          end

          backend_object = VirtualMachine.new(VirtualMachine.build_xml, client)

          rc = backend_object.allocate(template)
          check_rc(rc)
          OCCI::Log.debug("Return code from OpenNebula #{rc}") if rc != nil

          backend_object.info
          OCCI::Log.debug("OCCI Compute resource #{backend_object.inspect}")

          compute.id ||= self.generate_occi_id(@model.get_by_id(compute.kind), backend_object['ID'].to_s)

          compute_set_state(backend_object, compute)

          OCCI::Log.debug("OpenNebula automatically triggers action start for Virtual Machines")
          OCCI::Log.debug("Changing state to started")
        end

        # ---------------------------------------------------------------------------------------------------------------------
        def compute_set_state(backend_object, compute)
          OCCI::Log.debug("current VM state is: #{backend_object.lcm_state_str}")
          case backend_object.lcm_state_str
          when "RUNNING" then
            compute.attributes.occi!.compute!.state = "active"
            compute.actions                         = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#stop http://schemas.ogf.org/occi/infrastructure/compute/action#restart http://schemas.ogf.org/occi/infrastructure/compute/action#suspend|
          when "PROLOG", "BOOT", "SAVE_STOP", "SAVE_SUSPEND", "SAVE_MIGRATE", "MIGRATE", "PROLOG_MIGRATE", "PROLOG_RESUME", "LCM_INIT" then
            compute.attributes.occi!.compute!.state = "inactive"
            compute.actions                         = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#restart|
          when "SUSPENDED" then
            compute.attributes.occi!.compute!.state = "suspended"
            compute.actions                         = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#start|
          when "FAIL" then
            compute.attributes.occi!.compute!.state = "error"
            compute.actions                         = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#start|
          else
            compute.attributes.occi!.compute!.state = "inactive"
            compute.actions                         = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#start|
          end
        end

        # ---------------------------------------------------------------------------------------------------------------------
        def compute_delete(client, compute)
          backend_object=VirtualMachine.new(VirtualMachine.build_xml(@@location_cache[compute.id]), client)

          rc = backend_object.finalize
          check_rc(rc)
          # TODO: VNC
          #OCCI::Log.debug("killing NoVNC pipe with pid #{compute.backend[:novnc_pipe].pid}") unless compute.backend[:novnc_pipe].nil?
          #Process.kill 'INT', compute.backend[:novnc_pipe].pid unless compute.backend[:novnc_pipe].nil?
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # GET ALL COMPUTE INSTANCES
        def compute_register_all_instances(client)
          backend_object_pool = VirtualMachinePool.new(client)
          backend_object_pool.info_all
          backend_object_pool.each { |backend_object| compute_parse_backend_object(client, backend_object) }
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # COMPUTE ACTIONS
        # ---------------------------------------------------------------------------------------------------------------------

        # ---------------------------------------------------------------------------------------------------------------------
        def compute_action_dummy(compute, parameters)
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # COMPUTE Action start
        def compute_start(client, compute, parameters)
          backend_object = VirtualMachine.new(VirtualMachine.build_xml(@@location_cache[compute.id]), client)
          rc             = backend_object.resume
          check_rc(rc)
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # Action stop
        def compute_stop(client, compute, parameters)
          backend_object = VirtualMachine.new(VirtualMachine.build_xml(@@location_cache[compute.id]), client)
          # TODO: implement parameters when available in OpenNebula
          case parameters
          when 'method="graceful"'
            OCCI::Log.debug("Trying to stop VM graceful")
            rc = backend_object.shutdown
          when 'method="acpioff"'
            OCCI::Log.debug("Trying to stop VM via ACPI off")
            rc = backend_object.shutdown
          else # method="poweroff" or no method specified
            OCCI::Log.debug("Powering off VM")
            rc = backend_object.shutdown
          end
          check_rc(rc)
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # Action restart
        def compute_restart(client, compute, parameters)
          backend_object = VirtualMachine.new(VirtualMachine.build_xml(@@location_cache[compute.id]), client)
          # TODO: implement parameters when available in OpenNebula
          case parameters
          when "graceful"
            rc = backend_object.reboot
          when "warm"
            rc = backend_object.reboot
          else # "cold" or no parameter specified
            rc = backend_object.resubmit
          end
          check_rc(rc)
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # Action suspend
        def compute_suspend(client, compute, parameters)
          backend_object = VirtualMachine.new(VirtualMachine.build_xml(@@location_cache[compute.id]), client)
          rc = backend_object.suspend
          check_rc(rc)
        end

      end
    end
  end
end
