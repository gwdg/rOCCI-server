module Backends
  module Opennebula
    module Constants
      module Compute
        # State map
        STATE_MAP = {
          'RUNNING' => 'active',
          'PROLOG' => 'waiting',
          'BOOT' => 'waiting',
          'MIGRATE' => 'waiting',
          'EPILOG' => 'waiting',
          'LCM_INIT' => 'waiting'
        }.freeze

        # Attribute mapping hash for Core
        ATTRIBUTES_CORE = {
          'occi.core.id' => ->(vm) { vm['ID'] },
          'occi.core.title' => ->(vm) { vm['NAME'] },
          'occi.core.summary' => ->(vm) { vm['USER_TEMPLATE/DESCRIPTION'] }
        }.freeze

        # Attribute mapping hash for Infra
        ATTRIBUTES_INFRA = {
          'occi.compute.state' => lambda do |vm|
            return 'waiting' if vm.lcm_state_str.include?('HOTPLUG')
            return 'error' if vm.lcm_state_str.include?('FAILURE')
            STATE_MAP[vm.lcm_state_str] || 'inactive'
          end,
          'occi.compute.userdata' => lambda do |vm|
            return unless vm['TEMPLATE/CONTEXT/USERDATA_ENCODING'] == 'base64'
            vm['TEMPLATE/CONTEXT/USER_DATA']
          end,
          'occi.credentials.ssh.publickey' => lambda do |vm|
            vm['TEMPLATE/CONTEXT/SSH_KEY'] || vm['TEMPLATE/CONTEXT/SSH_PUBLIC_KEY']
          end
        }.freeze

        # All transferable attributes
        TRANSFERABLE_ATTRIBUTES = [ATTRIBUTES_CORE, ATTRIBUTES_INFRA].freeze

        # Attributes comparable between `resource_tpl` and `virtual_machine`
        COMPARABLE_ATTRIBUTES = {
          'occi.compute.cores' => ->(vm, val) { vm['TEMPLATE/VCPU'].to_i == val.to_i },
          'occi.compute.memory' => lambda do |vm, val|
            (vm['TEMPLATE/MEMORY'].to_f / 1024) == val.to_f
          end,
          'occi.compute.speed' => lambda do |vm, val|
            (vm['TEMPLATE/CPU'].to_f / vm['TEMPLATE/VCPU'].to_i) == val.to_f
          end,
          'occi.compute.ephemeral_storage.size' => lambda do |vm, val|
            (vm['TEMPLATE/DISK[1]/SIZE'].to_f / 1024) <= val.to_f
          end,
          'eu.egi.fedcloud.compute.gpu.count' => lambda do |vm, val|
            Backends::Opennebula::Helpers::Counter.xml_elements(vm, 'TEMPLATE/PCI') == val.to_i
          end,
          'eu.egi.fedcloud.compute.gpu.vendor' => ->(vm, val) { vm['TEMPLATE/PCI[1]/VENDOR'] == val },
          'eu.egi.fedcloud.compute.gpu.class' => ->(vm, val) { vm['TEMPLATE/PCI[1]/CLASS'] == val },
          'eu.egi.fedcloud.compute.gpu.device' => ->(vm, val) { vm['TEMPLATE/PCI[1]/DEVICE'] == val }
        }.freeze

        # Actions to enable when active
        ACTIVE_ACTIONS = {
          'stop' => ->(vm, _ai) { vm.poweroff(true) },
          'restart' => ->(vm, _ai) { vm.reboot(true) },
          'suspend' => ->(vm, _ai) { vm.suspend }
        }.freeze

        # Actions to enable when inactive
        INACTIVE_ACTIONS = {
          'start' => ->(vm, _ai) { vm.resume },
          'save' => lambda do |vm, ai|
            template_name = ai['name'].present? ? ai['name'] : "saved-compute-#{vm['ID']}-#{Time.now.utc.to_i}"
            vm.save_as_template(template_name, true)
          end
        }.freeze

        # All actions
        ACTIONS = ACTIVE_ACTIONS.merge(INACTIVE_ACTIONS).freeze
      end
    end
  end
end
