module Backends
  module Opennebula
    module Helpers
      module VirtualMachineMutators
        # Static user_data encoding
        USERDATA_ENCODING = 'base64'.freeze

        # :nodoc:
        def modify_basic!(template, compute, os_tpl)
          template.modify_element 'TEMPLATE/NAME', compute['occi.core.title'] || ::SecureRandom.uuid
          template.modify_element 'TEMPLATE/DESCRIPTION', compute['occi.core.summary'] || ''
          template.modify_element 'TEMPLATE/TEMPLATE_ID', os_tpl
        end

        # :nodoc:
        def set_context!(template, compute)
          template.modify_element 'TEMPLATE/CONTEXT/SSH_PUBLIC_KEY', compute['occi.credentials.ssh.publickey'] || ''
          template.modify_element 'TEMPLATE/CONTEXT/USERDATA_ENCODING', USERDATA_ENCODING
          template.modify_element 'TEMPLATE/CONTEXT/USER_DATA', compute['occi.compute.userdata'] || ''
        end

        # :nodoc:
        def set_size!(template, compute)
          template.modify_element 'TEMPLATE/VCPU', compute['occi.compute.cores']
          template.modify_element 'TEMPLATE/CPU', (compute['occi.compute.speed'] * compute['occi.compute.cores'])
          template.modify_element 'TEMPLATE/MEMORY', (compute['occi.compute.memory'] * 1024).to_i
          template.modify_element 'TEMPLATE/DISK[1]/SIZE', (compute['occi.compute.ephemeral_storage.size'] * 1024).to_i
        end

        # :nodoc:
        def set_security_groups!(template, compute)
          sgs = compute.securitygrouplinks.map(&:target_id).join(',')

          idx = 1
          template.each('TEMPLATE/NIC') do |_nic|
            template.modify_element "TEMPLATE/NIC[#{idx}]/SECURITY_GROUPS", sgs
            idx += 1
          end
        end

        # :nodoc:
        def set_cluster!(template, compute)
          az = compute.availability_zone ? compute.availability_zone.term : nil
          return unless az

          sched_reqs = template['TEMPLATE/SCHED_REQUIREMENTS'] || ''
          sched_reqs << ' & ' if sched_reqs.present?
          sched_reqs << "(CLUSTER_ID = #{az})"

          template.modify_element 'TEMPLATE/SCHED_REQUIREMENTS', sched_reqs
        end

        # :nodoc:
        def add_custom!(template_str, _compute)
          template_str << "\n USER_IDENTITY=\"#{active_identity}\""
          template_str << "\n USER_X509_DN=\"#{active_identity}\""
        end

        # :nodoc:
        def add_gpu!(template_str, compute)
          return unless compute['eu.egi.fedcloud.compute.gpu.count']

          gpu = {
            vendor: compute['eu.egi.fedcloud.compute.gpu.vendor'],
            klass: compute['eu.egi.fedcloud.compute.gpu.class'],
            device: compute['eu.egi.fedcloud.compute.gpu.device']
          }
          data = { instances: [] }
          compute['eu.egi.fedcloud.compute.gpu.count'].times { data[:instances] << gpu }

          add_erb! template_str, data, 'compute_pci.erb'
        end

        # :nodoc:
        def add_nics!(template_str, compute)
          data = {
            instances: compute.networkinterfaces,
            security_groups: compute.securitygrouplinks.map(&:target_id)
          }
          add_erb! template_str, data, 'compute_nic.erb'
        end

        # :nodoc:
        def add_disks!(template_str, compute)
          data = { instances: compute.storagelinks }
          add_erb! template_str, data, 'compute_disk.erb'
        end

        # :nodoc:
        def add_erb!(template_str, data, template_file)
          template_path = File.join(template_directory, template_file)

          template_str << "\n"
          template_str << erb_render(template_path, data)
        end
      end
    end
  end
end
