module Backends
  module Opennebula
    module Helpers
      module ComputeCreateHelper
        COMPUTE_SSH_REGEXP = /^(command=.+\s)?((?:ssh\-|ecds)[\w-]+\s.+)$/
        COMPUTE_BASE64_REGEXP = /^[A-Za-z0-9+\/]+={0,2}$/
        COMPUTE_USER_DATA_SIZE_LIMIT = 16384
        COMPUTE_DN_BASED_AUTHS = %w(x509 voms).freeze

        def compute_create_with_os_tpl(compute)
          @logger.debug "[Backends] [OpennebulaBackend] Deploying #{compute.inspect}"

          # include some basic mixins
          # WARNING: adding mix-ins will re-set their attributes
          attr_backup = Occi::Core::Attributes.new(compute.attributes)
          compute.mixins << 'http://opennebula.org/occi/infrastructure#compute'
          compute.attributes = attr_backup

          os_tpl_mixins = compute.mixins.get_related_to(Occi::Infrastructure::OsTpl.mixin.type_identifier)
          os_tpl = os_tpl_mixins.first

          @logger.debug "[Backends] [OpennebulaBackend] Deploying with OS template: #{os_tpl.term}"
          os_tpl = os_tpl_list_term_to_id(os_tpl.term)

          # get template
          template_alloc = ::OpenNebula::Template.build_xml(os_tpl)
          template = ::OpenNebula::Template.new(template_alloc, @client)
          rc = template.info
          check_retval(rc, Backends::Errors::ResourceRetrievalError)

          # update template
          compute_create_set_attrs(compute, template)
          compute_create_check_context(compute)
          compute_create_add_context(compute, template)
          compute_create_add_description(compute, template)
          compute_create_add_custom_template_vars(compute, template)

          # remove template-specific values
          template.delete_element('ID')
          template.delete_element('UID')
          template.delete_element('GID')
          template.delete_element('UNAME')
          template.delete_element('GNAME')
          template.delete_element('REGTIME')
          template.delete_element('PERMISSIONS')
          template.delete_element('TEMPLATE/TEMPLATE_ID')

          # convert template structure to a pure String
          template = template.template_str

          # add inline links
          template = compute_create_add_inline_links(compute, template)

          @logger.debug "[Backends] [OpennebulaBackend] Template #{template.inspect}"
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

        def compute_create_with_links(compute)
          # TODO: drop this branch in the second stable release
          fail Backends::Errors::MethodNotImplementedError,
               "This functionality has been deprecated! Use os_tpl and resource_tpl mixins!"
        end

        private

        def compute_create_set_attrs(compute, template)
          template.delete_element('TEMPLATE/NAME')
          template.add_element('TEMPLATE',  'NAME' => compute.title)

          if compute.cores
            # set number of cores
            template.delete_element('TEMPLATE/VCPU')
            template.add_element('TEMPLATE',  'VCPU' => compute.cores.to_i)

            # set reservation ratio
            template.delete_element('TEMPLATE/CPU')
            template.add_element('TEMPLATE',  'CPU' => compute.cores.to_i)
          end

          if compute.memory
            memory = compute.memory.to_f * 1024
            template.delete_element('TEMPLATE/MEMORY')
            template.add_element('TEMPLATE',  'MEMORY' => memory.to_i)
          end

          if compute.architecture
            template.delete_element('TEMPLATE/ARCHITECTURE')
            template.add_element('TEMPLATE',  'ARCHITECTURE' => compute.architecture)
          end

          # TODO: speed should contain a CPU speed (i.e. frequency in GHz)
          # if compute.speed
          #   ###
          # end
        end

        def compute_create_add_context(compute, template)
          return unless compute.attributes.org!.openstack

          template.add_element('TEMPLATE', 'CONTEXT' => '')

          if compute.attributes.org.openstack.credentials!.publickey!.data
            template.delete_element('TEMPLATE/CONTEXT/SSH_KEY')
            template.add_element('TEMPLATE/CONTEXT', 'SSH_KEY' => compute.attributes['org.openstack.credentials.publickey.data'])

            template.delete_element('TEMPLATE/CONTEXT/SSH_PUBLIC_KEY')
            template.add_element('TEMPLATE/CONTEXT', 'SSH_PUBLIC_KEY' => compute.attributes['org.openstack.credentials.publickey.data'])
          end

          if compute.attributes.org.openstack.compute!.user_data
            template.delete_element('TEMPLATE/CONTEXT/USER_DATA')
            template.add_element('TEMPLATE/CONTEXT', 'USER_DATA' => compute.attributes['org.openstack.compute.user_data'])

            template.delete_element('TEMPLATE/CONTEXT/USERDATA_ENCODING')
            template.add_element('TEMPLATE/CONTEXT', 'USERDATA_ENCODING' => 'base64')
          end
        end

        def compute_create_check_context(compute)
          if compute.attributes.org!.openstack!.credentials!.publickey!.data
            fail Backends::Errors::ResourceNotValidError, 'Public key is invalid!' unless \
              COMPUTE_SSH_REGEXP.match(compute.attributes['org.openstack.credentials.publickey.data'])
          end

          if compute.attributes.org!.openstack!.compute!.user_data
            fail Backends::Errors::ResourceNotValidError, "User data exceeds the allowed size of #{COMPUTE_USER_DATA_SIZE_LIMIT} bytes!" unless \
              compute.attributes['org.openstack.compute.user_data'].bytesize <= COMPUTE_USER_DATA_SIZE_LIMIT
          end

          if compute.attributes.org!.openstack!.compute!.user_data
            fail Backends::Errors::ResourceNotValidError, 'User data contains invalid characters!' unless \
              COMPUTE_BASE64_REGEXP.match(compute.attributes['org.openstack.compute.user_data'].gsub("\n", ''))
          end
        end

        def compute_create_add_description(compute, template)
          return if compute.blank? || template.nil?

          new_desc = if !compute.summary.blank?
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

        def compute_create_add_inline_links(compute, template)
          return template if compute.blank? || compute.links.blank?

          compute.links.to_a.each do |link|
            next unless link.kind_of? Occi::Core::Link
            @logger.debug "[Backends] [OpennebulaBackend] Handling inline link #{link.to_s.inspect}"

            case link.kind.type_identifier
            when 'http://schemas.ogf.org/occi/infrastructure#storagelink'
              template = compute_create_add_inline_storagelink(template, link)
            when 'http://schemas.ogf.org/occi/infrastructure#networkinterface'
              template = compute_create_add_inline_networkinterface(template, link)
            else
              fail Backends::Errors::ResourceNotValidError, "Link kind #{link.kind.type_identifier.inspect} is not supported!"
            end
          end

          template
        end

        def compute_create_add_inline_storagelink(template, storagelink)
          storage = storage_get(storagelink.target.split('/').last)
          @logger.debug "[Backends] [OpennebulaBackend] Linking storage #{storage.id.inspect} - #{storage.title.inspect}"

          disktemplate_location = File.join(@options.templates_dir, 'compute_disk.erb')
          disktemplate = Erubis::Eruby.new(File.read(disktemplate_location)).evaluate(storagelink: storagelink)

          template << disktemplate
        end

        def compute_create_add_inline_networkinterface(template, networkinterface)
          network = network_get(networkinterface.target.split('/').last)
          @logger.debug "[Backends] [OpennebulaBackend] Linking network #{network.id.inspect} - #{network.title.inspect}"

          nictemplate_location = File.join(@options.templates_dir, 'compute_nic.erb')
          nictemplate = Erubis::Eruby.new(File.read(nictemplate_location)).evaluate(networkinterface: networkinterface)

          template << nictemplate
        end

        def compute_create_add_custom_template_vars(compute, template)
          # add mixins
          mixins = compute.mixins.to_a.map { |m| m.type_identifier }
          template.add_element('TEMPLATE',  'OCCI_COMPUTE_MIXINS' => mixins.join(' '))

          # add user identity info
          template.add_element('TEMPLATE',  'USER_IDENTITY' => @delegated_user.identity)
          if COMPUTE_DN_BASED_AUTHS.include?(@delegated_user.auth_.type)
            template.add_element('TEMPLATE',  'USER_X509_DN' => @delegated_user.identity)
          end
        end
      end
    end
  end
end
