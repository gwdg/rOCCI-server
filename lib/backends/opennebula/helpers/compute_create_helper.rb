module Backends
  module Opennebula
    module Helpers
      module ComputeCreateHelper
        COMPUTE_SSH_REGEXP = /^(command=.+\s)?((?:ssh\-|ecds)[\w-]+\s.+)$/
        COMPUTE_BASE64_REGEXP = /^[A-Za-z0-9+\/]+={0,2}$/

        def compute_create_with_os_tpl(compute)
          @logger.debug "[Backends] [OpennebulaBackend] Deploying #{compute.inspect}"

          os_tpl_mixins = compute.mixins.get_related_to(Occi::Infrastructure::OsTpl.mixin.type_identifier)
          os_tpl = os_tpl_mixins.first

          @logger.debug "[Backends] [OpennebulaBackend] Deploying with OS template: #{os_tpl.term}"
          os_tpl = os_tpl_list_term_to_id(os_tpl.term)

          template_alloc = ::OpenNebula::Template.build_xml(os_tpl)
          template = ::OpenNebula::Template.new(template_alloc, @client)
          rc = template.info
          check_retval(rc, Backends::Errors::ResourceRetrievalError)

          template.delete_element('TEMPLATE/NAME')
          template.add_element('TEMPLATE',  'NAME' => compute.title)

          if compute.cores
            template.delete_element('TEMPLATE/VCPU')
            template.add_element('TEMPLATE',  'VCPU' => compute.cores.to_i)
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

          if compute.speed
            calc_speed = compute.speed.to_f * (template['TEMPLATE/VCPU'] || 1).to_i
            template.delete_element('TEMPLATE/CPU')
            template.add_element('TEMPLATE',  'CPU' => calc_speed)
          end

          compute_create_check_context(compute)
          compute_create_add_context(compute, template)

          mixins = compute.mixins.to_a.map { |m| m.type_identifier }
          template.add_element('TEMPLATE',  'OCCI_COMPUTE_MIXINS' => mixins.join(' '))

          # remove template-specific values
          template.delete_element('ID')
          template.delete_element('UID')
          template.delete_element('GID')
          template.delete_element('UNAME')
          template.delete_element('GNAME')
          template.delete_element('REGTIME')
          template.delete_element('PERMISSIONS')
          template.delete_element('TEMPLATE/TEMPLATE_ID')

          template = template.template_str
          @logger.debug "[Backends] [OpennebulaBackend] Template #{template.inspect}"

          vm_alloc = ::OpenNebula::VirtualMachine.build_xml
          backend_object = ::OpenNebula::VirtualMachine.new(vm_alloc, @client)

          rc = backend_object.allocate(template)
          check_retval(rc, Backends::Errors::ResourceCreationError)

          rc = backend_object.info
          check_retval(rc, Backends::Errors::ResourceRetrievalError)

          backend_object['ID']
        end

        def compute_create_with_links(compute)
          # TODO: fix or drop this part
          # TODO: needs clean-up and DRYing with compute_create_with_os_tpl
          # TODO: especially CONTEXT handling
          fail Backends::Errors::MethodNotImplementedError,
               "This functionality has been deprecated! Use os_tpl and resource_tpl mixins!"

          @logger.debug "[Backends] [OpennebulaBackend] Deploying #{compute.inspect} with links"
          template_location = File.join(@options.templates_dir, 'compute.erb')
          template = Erubis::Eruby.new(File.read(template_location)).evaluate(compute: compute)

          @logger.debug "[Backends] [OpennebulaBackend] Template #{template.inspect}"

          vm_alloc = ::OpenNebula::VirtualMachine.build_xml
          backend_object = ::OpenNebula::VirtualMachine.new(vm_alloc, @client)

          rc = backend_object.allocate(template)
          check_retval(rc, Backends::Errors::ResourceCreationError)

          rc = backend_object.info
          check_retval(rc, Backends::Errors::ResourceRetrievalError)

          backend_object['ID']
        end

        private

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
            template.add_element('TEMPLATE/CONTEXT', 'USER_DATA' => compute_create_add_context_ud4ci(compute.attributes['org.openstack.compute.user_data']))
          end
        end

        def compute_create_check_context(compute)
          if compute.attributes.org!.openstack!.credentials!.publickey!.data
            fail Backends::Errors::ResourceNotValidError, 'Public key is invalid!' unless \
              COMPUTE_SSH_REGEXP.match(compute.attributes['org.openstack.credentials.publickey.data'])
          end

          if compute.attributes.org!.openstack!.compute!.user_data
            fail Backends::Errors::ResourceNotValidError, 'User data contains invalid characters!' unless \
              COMPUTE_BASE64_REGEXP.match(compute.attributes['org.openstack.compute.user_data'].gsub("\n", ''))
          end
        end

        # Decodes Base64-encoded USER_DATA and check whether this is a cloud-init
        # configuration file or just an arbitrary content. USER_DATA for cloud-init
        # will be decoded into its original form, arbitrary content will stay encoded
        # in Base64 and returned.
        #
        # @param user_data [String] Base64-encoded USER_DATA
        # @return [String] decoded cloud-init config or Base64-encoded original content
        def compute_create_add_context_ud4ci(user_data)
          return '' if user_data.blank?

          begin
            decoded = Base64.strict_decode64(user_data)
            decoded.match(/^\s*#cloud-config\s*$/) ? decoded : user_data
          rescue => e
            @logger.error "[Backends] [OpennebulaBackend] Failed to decode USER_DATA! #{e.message}"
            fail Backends::Errors::ResourceNotValidError, "Couldn't decode USER_DATA from Base64!"
          end
        end
      end
    end
  end
end
