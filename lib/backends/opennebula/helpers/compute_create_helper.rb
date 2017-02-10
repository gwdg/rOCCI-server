module Backends
  module Opennebula
    module Helpers
      module ComputeCreateHelper
        COMPUTE_SSH_REGEXP = /^(command=.+\s)?((?:ssh\-|ecds)[\w-]+\s.+)$/
        COMPUTE_BASE64_REGEXP = /^[A-Za-z0-9+\/]+={0,2}$/
        COMPUTE_USER_DATA_SIZE_LIMIT = 16384
        COMPUTE_DEFAULT_RES_TPL = 'http://fedcloud.egi.eu/occi/compute/flavour/1.0#small'.freeze

        def create_with_os_tpl(compute)
          @logger.debug "[Backends] [Opennebula] Deploying #{compute.inspect}"

          os_tpl_mixins = compute.mixins.get_related_to(::Occi::Infrastructure::OsTpl.mixin.type_identifier)
          os_tpl = os_tpl_mixins.first

          @logger.debug "[Backends] [Opennebula] Deploying with OS template: #{os_tpl.term}"
          os_tpl = term_to_id(os_tpl.term)

          # get template
          template_alloc = ::OpenNebula::Template.build_xml(os_tpl)
          template = ::OpenNebula::Template.new(template_alloc, @client)
          rc = template.info
          check_retval(rc, Backends::Errors::ResourceRetrievalError)

          # update template
          create_set_attrs(compute, template)
          create_check_context(compute)
          create_add_context(compute, template)
          create_add_description(compute, template)
          create_add_custom_template_vars(compute, template)

          # remove template-specific values
          elms = %w(ID UID GID UNAME GNAME REGTIME PERMISSIONS TEMPLATE/TEMPLATE_ID)
          create_clean_tpl(template, elms)

          # convert template structure to a pure String
          template = template.template_str

          # add inline links
          create_add_inline_links(compute, template)

          # add GPU devices
          create_add_gpu_devs(create_get_size(compute), template)

          @logger.debug "[Backends] [Opennebula] Template #{template.inspect}"
          vm_alloc = ::OpenNebula::VirtualMachine.build_xml
          backend_object = ::OpenNebula::VirtualMachine.new(vm_alloc, @client)

          rc = backend_object.allocate(template)
          check_retval(rc, Backends::Errors::ResourceCreationError)

          rc = backend_object.info
          check_retval(rc, Backends::Errors::ResourceRetrievalError)

          compute_id = backend_object['ID']
          rc = backend_object.update("OCCI_ID=\"#{compute_id}\"", true)
          check_retval(rc, Backends::Errors::ResourceActionError)

          compute_id
        end

        private

        def create_clean_tpl(template, elms)
          elms.each { |elm| template.delete_element(elm) }
        end

        def create_get_size(compute)
          resource_tpl = compute.mixins.get_related_to(::Occi::Infrastructure::ResourceTpl.mixin.type_identifier).first
          resource_tpl ? resource_tpl : compute.model.get_by_id(COMPUTE_DEFAULT_RES_TPL)
        end

        def create_set_attrs(compute, template)
          template.delete_element('TEMPLATE/NAME')
          cmpt_title = compute.title.blank? ? SecureRandom.uuid : compute.title
          template.add_element('TEMPLATE',  'NAME' => cmpt_title)

          create_set_size(create_get_size(compute), template)
        end

        def create_set_size(resource_tpl, template)
          cores = resource_tpl.attributes['occi.compute.cores'].default.to_i
          speed = resource_tpl.attributes['occi.compute.speed'].default.to_f
          memory = resource_tpl.attributes['occi.compute.memory'].default.to_f
          eph_storage = resource_tpl.attributes['occi.compute.ephemeral_storage.size'].default.to_i

          # set number of cores
          template.delete_element('TEMPLATE/VCPU')
          template.add_element('TEMPLATE',  'VCPU' => cores)

          # set default reservation ratio
          template.delete_element('TEMPLATE/CPU')
          cpu_resrv = speed ? (speed * cores) : cores
          template.add_element('TEMPLATE',  'CPU' => cpu_resrv)

          # set memory in MB (conversion from GB)
          template.delete_element('TEMPLATE/MEMORY')
          template.add_element('TEMPLATE',  'MEMORY' => (memory * 1024).to_i)

          # resize OS disk in MB (conversion from GB)
          if eph_storage > 0
            template.delete_element('TEMPLATE/DISK[1]/SIZE')
            template.add_element('TEMPLATE/DISK[1]',  'SIZE' => (eph_storage * 1024))
          end
        end

        def create_add_context(compute, template)
          pbk = compute.attributes.occi!.credentials!.ssh!.publickey || compute.attributes.org!.openstack!.credentials!.publickey!.data
          ud  = compute.attributes.occi!.compute!.userdata || compute.attributes.org!.openstack!.compute!.user_data
          return unless pbk || ud

          template.add_element('TEMPLATE', 'CONTEXT' => '')

          if pbk
            template.delete_element('TEMPLATE/CONTEXT/SSH_KEY')
            template.add_element('TEMPLATE/CONTEXT', 'SSH_KEY' => pbk)

            template.delete_element('TEMPLATE/CONTEXT/SSH_PUBLIC_KEY')
            template.add_element('TEMPLATE/CONTEXT', 'SSH_PUBLIC_KEY' => pbk)
          end

          if ud
            template.delete_element('TEMPLATE/CONTEXT/USER_DATA')
            template.add_element('TEMPLATE/CONTEXT', 'USER_DATA' => ud)

            template.delete_element('TEMPLATE/CONTEXT/USERDATA_ENCODING')
            template.add_element('TEMPLATE/CONTEXT', 'USERDATA_ENCODING' => 'base64')
          end
        end

        def create_check_context(compute)
          pbk = compute.attributes.occi!.credentials!.ssh!.publickey || compute.attributes.org!.openstack!.credentials!.publickey!.data
          ud  = compute.attributes.occi!.compute!.userdata || compute.attributes.org!.openstack!.compute!.user_data

          fail Backends::Errors::ResourceNotValidError,
               'Public key is invalid!' if pbk && !COMPUTE_SSH_REGEXP.match(pbk)

          return if ud.blank?

          fail Backends::Errors::ResourceNotValidError,
               "User data exceeds the allowed size of #{COMPUTE_USER_DATA_SIZE_LIMIT} bytes!" if ud.bytesize > COMPUTE_USER_DATA_SIZE_LIMIT

          fail Backends::Errors::ResourceNotValidError,
               'User data contains invalid characters!' unless COMPUTE_BASE64_REGEXP.match ud.gsub("\n", '')
        end

        def create_add_description(compute, template)
          return if compute.blank? || template.nil?

          new_desc =
            if !compute.summary.blank?
              compute.summary
            elsif !template['TEMPLATE/DESCRIPTION'].blank?
              "#{template['TEMPLATE/DESCRIPTION']}#{template['TEMPLATE/DESCRIPTION'].end_with?('.') ? '' : '.' }" \
              " Instantiated with rOCCI-server on #{::DateTime.now.readable_inspect}."
            else
              "Instantiated with rOCCI-server on #{::DateTime.now.readable_inspect}."
            end

          template.delete_element('TEMPLATE/DESCRIPTION')
          template.add_element('TEMPLATE', 'DESCRIPTION' => new_desc)
        end

        def create_add_inline_links(compute, template)
          return if compute.blank? || compute.links.blank?

          compute.links.to_a.each do |link|
            next unless link.kind_of? ::Occi::Core::Link
            @logger.debug "[Backends] [Opennebula] Handling inline link #{link.to_s.inspect}"

            case link
            when ::Occi::Infrastructure::Storagelink
              create_add_inline_storagelink(template, link)
            when ::Occi::Infrastructure::Networkinterface
              create_add_inline_networkinterface(template, link)
            else
              fail Backends::Errors::ResourceNotValidError, "Link kind #{link.kind.type_identifier.inspect} is not supported!"
            end
          end
        end

        def create_add_inline_storagelink(template, storagelink)
          storage = @other_backends['storage'].get(storagelink.target.split('/').last)
          @logger.debug "[Backends] [Opennebula] Linking storage #{storage.id.inspect} - #{storage.title.inspect}"

          disktemplate_location = File.join(@options.templates_dir, 'compute_disk.erb')
          disktemplate = Erubis::Eruby.new(File.read(disktemplate_location)).evaluate(storagelink: storagelink)

          template << disktemplate
        end

        def create_add_inline_networkinterface(template, networkinterface)
          network = @other_backends['network'].get(networkinterface.target.split('/').last)
          @logger.debug "[Backends] [Opennebula] Linking network #{network.id.inspect} - #{network.title.inspect}"

          nictemplate_location = File.join(@options.templates_dir, 'compute_nic.erb')
          nictemplate = Erubis::Eruby.new(File.read(nictemplate_location)).evaluate(networkinterface: networkinterface)

          template << nictemplate
        end

        def create_add_custom_template_vars(compute, template)
          # add mixins
          mixins = compute.mixins.to_a.map { |m| m.type_identifier }
          mixins << create_get_size(compute).type_identifier
          mixins.uniq!
          template.add_element('TEMPLATE',  'OCCI_COMPUTE_MIXINS' => mixins.join(' '))

          # add user identity info
          template.add_element('TEMPLATE',  'USER_IDENTITY' => @delegated_user.identity)
          if Backends::Opennebula::Compute::DN_BASED_AUTHS.include?(@delegated_user.auth_.type)
            template.add_element('TEMPLATE',  'USER_X509_DN' => @delegated_user.identity)
          end
        end

        def create_add_gpu_devs(resource_tpl, template)
          # TODO: this needs to be improved in future versions
          # Expected attributes:
          #   - eu.egi.fedcloud.compute.gpu.count  (Integer)
          #   - eu.egi.fedcloud.compute.gpu.vendor (String)
          #   - eu.egi.fedcloud.compute.gpu.class  (String)
          #   - eu.egi.fedcloud.compute.gpu.device (String)
          return unless resource_tpl.attributes.eu!.egi!.fedcloud!.compute!.gpu

          vendor = resource_tpl.attributes['eu.egi.fedcloud.compute.gpu.vendor'].default
          klass = resource_tpl.attributes['eu.egi.fedcloud.compute.gpu.class'].default
          device = resource_tpl.attributes['eu.egi.fedcloud.compute.gpu.device'].default
          count = resource_tpl.attributes['eu.egi.fedcloud.compute.gpu.count'].default.to_i

          pci_tpl = []
          pci_tpl << "VENDOR=\"#{vendor}\"" unless vendor.blank?
          pci_tpl << "CLASS=\"#{klass}\"" unless klass.blank?
          pci_tpl << "DEVICE=\"#{device}\"" unless device.blank?
          return if pci_tpl.empty?

          @logger.debug "[Backends] [Opennebula] Adding GPU(s) #{pci_tpl.inspect}"
          template << "\n"
          count.times { template << "PCI = [ #{pci_tpl.join(',')} ]\n" }
        end
      end
    end
  end
end
