module Backends
  module Opennebula
    module Helpers
      module ComputeUpdateHelper
        COMPUTE_UPDATE_STATES = %w(POWEROFF UNDEPLOYED PENDING STOPPED).freeze

        def update_instance_size(instance_id, resource_tpl)
          virtual_machine = ::OpenNebula::VirtualMachine.new(::OpenNebula::VirtualMachine.build_xml(instance_id), @client)
          rc = virtual_machine.info
          check_retval(rc, Backends::Errors::ResourceRetrievalError)

          update_instance_size_stop(virtual_machine)
          update_instance_size_apply(virtual_machine, resource_tpl)
          update_instance_size_start(virtual_machine)
        end

        def update_instance_size_stop(virtual_machine)
          return if COMPUTE_UPDATE_STATES.include? virtual_machine.state_str

          rc = virtual_machine.poweroff(true)
          check_retval(rc, Backends::Errors::ResourceActionError)
          compute_wait_for(virtual_machine, 'POWEROFF')
        end

        def update_instance_size_apply(virtual_machine, resource_tpl)
          cores = resource_tpl.attributes['occi.compute.cores'].default.to_i
          memory = (resource_tpl.attributes['occi.compute.memory'].default.to_f * 1024).to_i
          speed = resource_tpl.attributes['occi.compute.speed'].default.to_f * cores

          resize_template = ''
          resize_template << "VCPU = #{cores}\n"
          resize_template << "CPU = #{speed}\n"
          resize_template << "MEMORY = #{memory}"

          # TODO: resize disk, if possible
          rc = virtual_machine.resize(resize_template, true)
          check_retval(rc, Backends::Errors::ResourceActionError)

          update_instance_size_mixins(virtual_machine, resource_tpl)
        end

        def update_instance_size_mixins(virtual_machine, resource_tpl)
          old_mixins = virtual_machine['USER_TEMPLATE/OCCI_COMPUTE_MIXINS']
          return if old_mixins.blank?

          old_mixins = old_mixins.split(' ').reject do |mxn|
            mxn = resource_tpl.model.get_by_id(mxn)
            mxn.blank? || mxn.related_to?(Occi::Infrastructure::ResourceTpl.mixin.type_identifier)
          end
          old_mixins << resource_tpl.type_identifier

          user_template = "OCCI_COMPUTE_MIXINS=\"#{old_mixins.join(' ')}\""
          rc = virtual_machine.update(user_template, true)
          check_retval(rc, Backends::Errors::ResourceActionError)
        end

        def update_instance_size_start(virtual_machine)
          rc = virtual_machine.info
          check_retval(rc, Backends::Errors::ResourceRetrievalError)
          return if virtual_machine.state_str == 'PENDING'

          rc = virtual_machine.resume
          check_retval(rc, Backends::Errors::ResourceActionError)
        end

        def update_instance_resize_tpl(mixins)
          res_tpls = mixins.to_a.select { |mxn| mxn.related_to? Occi::Infrastructure::ResourceTpl.mixin.type_identifier }
          fail Backends::Errors::ResourceActionError,
               'Only resizing is supported! Cannot resize instance to an unknown size!' if res_tpls.empty?

          orig_tpl = res_tpls.first.model.get_by_id(res_tpls.first.type_identifier)
          fail Backends::Errors::ResourceActionError,
               'Cannot find the specified resource tpl in the model!' unless orig_tpl

          orig_tpl
        end
      end
    end
  end
end
