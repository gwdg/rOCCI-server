module Backends
  module Opennebula
    module Helpers

      module ComputeCreateHelper

        COMPUTE_SSH_REGEXP = /^(command=.+\s)?((?:ssh\-|ecds)[\w-]+\s.+)$/
        COMPUTE_BASE64_REGEXP = /^[A-Za-z0-9+\/]+={0,2}$/

        def compute_create_with_os_tpl(compute)
          @logger.debug "Deploying #{compute.inspect}"

          os_tpl_mixins = compute.mixins.get_related_to(Occi::Infrastructure::OsTpl.mixin.type_identifier)
          os_tpl = os_tpl_mixins.first

          @logger.debug("Deploying with OS template: #{os_tpl.term}")
          os_tpl = os_tpl_list_term_to_id(os_tpl.term)

          template_alloc = ::OpenNebula::Template.build_xml(os_tpl)
          template = ::OpenNebula::Template.new(template_alloc, @client)
          rc = template.info
          check_retval(rc, Backends::Errors::ResourceRetrievalError)

          template.delete_element('TEMPLATE/NAME')
          template.add_element('TEMPLATE', { 'NAME' => compute.title })

          if compute.cores
            template.delete_element('TEMPLATE/VCPU')
            template.add_element('TEMPLATE', { "VCPU" => compute.cores.to_i })
          end

          if compute.memory
            memory = compute.memory.to_f * 1024
            template.delete_element('TEMPLATE/MEMORY')
            template.add_element('TEMPLATE', { "MEMORY" => memory.to_i })
          end

          if compute.architecture
            template.delete_element('TEMPLATE/ARCHITECTURE')
            template.add_element('TEMPLATE', { "ARCHITECTURE" => compute.architecture })
          end

          if compute.speed
            template.delete_element('TEMPLATE/CPU')
            template.add_element('TEMPLATE', { "CPU" => compute.speed.to_f })
          end

          compute_create_check_context(compute)
          compute_create_add_context(compute, template)

          mixins = compute.mixins.to_a.collect { |m| m.type_identifier }
          template.add_element('TEMPLATE', { "OCCI_COMPUTE_MIXINS" => mixins.join(' ') })

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
          @logger.debug "Template #{template.inspect}"

          vm_alloc = ::OpenNebula::VirtualMachine.build_xml
          backend_object = ::OpenNebula::VirtualMachine.new(vm_alloc, @client)

          rc = backend_object.allocate(template)
          check_retval(rc, Backends::Errors::ResourceCreationError)

          rc = backend_object.info
          check_retval(rc, Backends::Errors::ResourceRetrievalError)

          backend_object['ID']
        end

        def compute_create_with_links(compute)
          @logger.debug "Deploying #{compute.inspect} with links"
          template_location = File.join(@options.templates_dir, "compute.erb")
          template = Erubis::Eruby.new(File.read(template_location)).evaluate({ :compute => compute })

          @logger.debug "Template #{template.inspect}"

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

          template.add_element('TEMPLATE', "CONTEXT" => '')

          if compute.attributes.org.openstack.credentials!.publickey!.data
            template.delete_element('TEMPLATE/CONTEXT/SSH_KEY')
            template.add_element('TEMPLATE/CONTEXT', "SSH_KEY" => compute.attributes['org.openstack.credentials.publickey.data'])

            template.delete_element('TEMPLATE/CONTEXT/SSH_PUBLIC_KEY')
            template.add_element('TEMPLATE/CONTEXT', "SSH_PUBLIC_KEY" => compute.attributes['org.openstack.credentials.publickey.data'])
          end

          if compute.attributes.org.openstack.compute!.user_data
            template.delete_element('TEMPLATE/CONTEXT/USER_DATA')
            template.add_element('TEMPLATE/CONTEXT', "USER_DATA" => compute.attributes['org.openstack.compute.user_data'])
          end
        end

        def compute_create_check_context(compute)
          if compute.attributes.org!.openstack!.credentials!.publickey!.data
            raise Backends::Errors::ResourceNotValidError, 'Public key is invalid!' unless \
              COMPUTE_SSH_REGEXP.match(compute.attributes['org.openstack.credentials.publickey.data'])
          end

          if compute.attributes.org!.openstack!.compute!.user_data
            raise Backends::Errors::ResourceNotValidError, 'User data contains invalid characters!' unless \
              COMPUTE_BASE64_REGEXP.match(compute.attributes['org.openstack.compute.user_data'].gsub("\n", ''))
          end
        end

      end

    end
  end
end