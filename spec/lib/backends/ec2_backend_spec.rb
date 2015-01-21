require 'spec_helper'
require 'yaml'

describe Backends::Ec2Backend do
  let(:dalli) { Dalli::Client.new }
  let(:aws_creds) { ::Aws::Credentials.new('a', 'b') }
  let(:ec2_dummy_client) { ::Aws::EC2::Client.new(credentials: aws_creds, stub_responses: true) }
  let(:instance_statuses_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/instance_statuses_stub.yml") }
  let(:reservations_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/reservations_stub.yml") }
  let(:reservations_w_inval_res_tpl_stub) { reservations = reservations_stub
    reservations[:reservations].each { |res| res[:instances].each { |ins| ins[:instance_type] = 'nofixture' }}
    reservations }
  let(:reservations_waiting_stub) { reservations = reservations_stub
    reservations[:reservations].each { |res| res[:instances].each { |ins| ins[:state] = { :code => 0, :name => 'pending' }}}
    reservations }
  let(:reservations_inactive_stub) { reservations = reservations_stub
    reservations[:reservations].each { |res| res[:instances].each { |ins| ins[:state] = { :code => 48, :name => 'terminated' }}}
    reservations }
  let(:reservations_w_o_netlinks_stub) { reservations = reservations_stub
    reservations[:reservations].each { |res| res[:instances].each { |ins| ins[:network_interfaces] = [] }}
    reservations }
  let(:reservation_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/reservation_stub.yml") }
  let(:reservations_storagelink_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/reservations_storagelink_stub.yml") }
  let(:reservations_stopped_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/reservations_stopped_stub.yml") }
  let(:volumes_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/volumes_stub.yml") }
  let(:volumes_w_name_tag_stub) { volumes = volumes_stub
    volumes[:volumes].each { |vol| vol[:tags] = [ {:key => "Name", :value => "Testname"} ] }
    volumes }
  let(:volumes_error_stub) { volumes = volumes_stub
    volumes[:volumes].each { |vol| vol[:state] = "error" }
    volumes }
  let(:volumes_storagelink_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/volumes_storagelink_stub.yml") }
  let(:volumes_deleted_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/volumes_deleted_stub.yml") }
  let(:volume_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/volume_stub.yml") }
  let(:volume_statuses_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/volume_statuses_stub.yml") }
  let(:volume_attaching_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/volume_attaching_stub.yml") }
  let(:volume_detaching_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/volume_detaching_stub.yml") }
  let(:vpcs_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/vpcs_stub.yml") }
  let(:vpcs_w_name_tag_stub) { vpcs = vpcs_stub
    vpcs[:vpcs].first[:tags] = [ {:key => "Name", :value => "Testname"} ]
    vpcs }
  let(:vpcs_pending_stub) { vpcs = vpcs_stub
    vpcs[:vpcs].first[:state] = "pending"
    vpcs }
  let(:vpc_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/vpc_stub.yml") }
  let(:subnet_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/subnet_stub.yml") }
  let(:empty_struct_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/empty_struct_stub.yml") }
  let(:internet_gateway_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/internet_gateway_stub.yml") }
  let(:terminating_instances_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/terminating_instances_stub.yml") }
  let(:terminating_instances_single_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/terminating_instances_single_stub.yml") }
  let(:images_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/images_stub.yml") }
  let(:association_id_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/association_id_stub.yml") }
  let(:allocation_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/allocation_stub.yml") }
  let(:addresses_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/addresses_stub.yml") }
  let(:stopping_instances_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/stopping_instances_stub.yml") }
  let(:starting_instances_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/starting_instances_stub.yml") }

  let(:ec2_backend_delegated_user) do
    user = Hashie::Mash.new
    user.identity = "dummy_test_user"
    user
  end
  let(:ec2_backend_instance) do
    options = YAML.load(ERB.new(File.read("#{Rails.root}/etc/backends/ec2/test.yml")).result)
    instance = Backends::Ec2Backend.new ec2_backend_delegated_user, options, nil, nil, dalli
    instance.instance_variable_set(:@ec2_client, ec2_dummy_client)

    instance
  end
  let(:default_options) { ec2_backend_instance.instance_variable_get(:@options) }
  let(:default_image_filtering_policy) { ec2_backend_instance.instance_variable_get(:@image_filtering_policy) }

  before(:each) { dalli.flush }
  after(:all) { Dalli::Client.new.flush }

  context 'compute' do
    describe 'compute_list_ids' do
      it 'runs with empty list' do
        expect(ec2_backend_instance.compute_list_ids).to eq([])
      end

      it 'receives compute instance list correctly' do
        ec2_dummy_client.stub_responses(:describe_instance_status, instance_statuses:instance_statuses_stub)
        expect(ec2_backend_instance.compute_list_ids).to eq(["ID", "ID2"])
      end
    end

    describe '.compute_list' do
      it 'runs with empty list' do
        expect(ec2_backend_instance.compute_list).to eq([])
      end

      it 'receives compute instance list correctly with nil volume description' do
        ec2_dummy_client.stub_responses(:describe_instances, reservations_stub)
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        expect { ec2_backend_instance.compute_list }.not_to raise_exception
        expect(ec2_backend_instance.compute_list.count).to eq(2)
      end

      it 'receives compute instance list correctly with nil vpc description' do
        ec2_dummy_client.stub_responses(:describe_instances, reservations_stub)
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        expect { ec2_backend_instance.compute_list }.not_to raise_exception
        expect(ec2_backend_instance.compute_list.count).to eq(2)
      end

      it 'receives compute instance list correctly' do
        ec2_dummy_client.stub_responses(:describe_instances, reservations_stub)
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        expect(ec2_backend_instance.compute_list.as_json).to eq YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_samples/compute_list.yml")
      end
    end

    describe '.compute_get' do
      it 'copes with non-existent id' do
        expect(ec2_backend_instance.compute_get("someID")).to eq nil
      end

      it 'gets compute instance description correctly' do
        ec2_dummy_client.stub_responses(:describe_instances, reservations_stub)
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        expect(ec2_backend_instance.compute_get("i-22af91c7").as_json).to eq YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_samples/compute_list_single_instance.yml")
      end

      it 'gets compute instance description correctly' do
        ec2_dummy_client.stub_responses(:describe_instances, reservations_w_inval_res_tpl_stub)
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        expect(ec2_backend_instance.compute_get("i-22af91c7").as_json.mixins).to include "http://schemas.ec2.aws.amazon.com/occi/infrastructure/resource_tpl#nofixture"
      end

      it 'gets compute instance description correctly with state waiting' do
        ec2_dummy_client.stub_responses(:describe_instances, reservations_waiting_stub)
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        expect(ec2_backend_instance.compute_get("i-22af91c7").attributes.occi.compute.state).to eq "waiting"
      end

      it 'gets compute instance description correctly with state inactive' do
        ec2_dummy_client.stub_responses(:describe_instances, reservations_inactive_stub)
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        expect(ec2_backend_instance.compute_get("i-22af91c7").attributes.occi.compute.state).to eq "inactive"
      end

      it 'gets compute instance description correctly with no network links' do
        ec2_dummy_client.stub_responses(:describe_instances, reservations_w_o_netlinks_stub)
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        expect(ec2_backend_instance.compute_get("i-22af91c7").links.count).to eq 3
      end
    end

    describe '.compute_create' do
      it 'reports correctly on missing os_tpl mixin' do
        compute = Occi::Infrastructure::Compute.new
        expect{ec2_backend_instance.compute_create(compute)}.to raise_exception(Backends::Errors::ResourceNotValidError)
      end

      it 'creates compute resource correctyly' do
        ec2_dummy_client.stub_responses(:run_instances, reservation_stub)

        ostemplate = Occi::Core::Mixin.new("http://occi.localhost/occi/infrastructure/os_tpl#", "ami-6e7bd919")
        ostemplate.depends=[Occi::Infrastructure::OsTpl.mixin]
        restemplate = Occi::Core::Mixin.new("http://schemas.ec2.aws.amazon.com/occi/infrastructure/resource_tpl#", "t2_micro")
        restemplate.depends=[Occi::Infrastructure::ResourceTpl.mixin]
        compute = Occi::Infrastructure::Compute.new
        compute.mixins << ostemplate
        compute.mixins << restemplate
        expect(ec2_backend_instance.compute_create(compute)).to eq "i-5a8cb7bf"
      end
    end


    describe '.compute_delete_all' do
      it 'deletes all instances' do
        ec2_dummy_client.stub_responses(:terminate_instances, terminating_instances_stub)
        ec2_dummy_client.stub_responses(:describe_instance_status, instance_statuses:instance_statuses_stub)
        expect(ec2_backend_instance.compute_delete_all).to be true
      end
    end


    describe '.compute_delete' do
      it 'deletes the given instance' do
        ec2_dummy_client.stub_responses(:terminate_instances, terminating_instances_single_stub)
        ec2_dummy_client.stub_responses(:describe_instance_status, instance_statuses:instance_statuses_stub)
        expect(ec2_backend_instance.compute_delete("i-5a8cb7bf")).to be true
      end

      it 'copes with invalid ID' do
        ec2_dummy_client.stub_responses(:terminate_instances, Aws::EC2::Errors::InvalidInstanceIDMalformed)
        ec2_dummy_client.stub_responses(:describe_instance_status, instance_statuses:instance_statuses_stub)
        expect{ec2_backend_instance.compute_delete("xxxxxxxxxx")}.to raise_exception{Backends::Errors::IdentifierNotValidError}
      end
    end

    describe '.compute_attach_network' do
      it 'Correctly reports unsupported operation trying to attach VPC' do
        network = Occi::Infrastructure::Network.new
        network.address='10.0.0.0/24'
        networkinterface = Occi::Infrastructure::Networkinterface.new
        networkinterface.target = network
        networkinterface.source = Occi::Infrastructure::Compute.new
        expect{ec2_backend_instance.compute_attach_network(networkinterface)}.to raise_exception(Backends::Errors::ResourceCreationError)
      end

      it 'Reports correctly on missing source' do
        network = Occi::Infrastructure::Network.new
        network.address='10.0.0.0/24'
        networkinterface = Occi::Infrastructure::Networkinterface.new
        networkinterface.target = network
        expect{ec2_backend_instance.compute_attach_network(networkinterface)}.to raise_exception(Backends::Errors::ResourceNotValidError)
      end

      it 'Reports correctly on missing target' do
        networkinterface = Occi::Infrastructure::Networkinterface.new
        networkinterface.source = Occi::Infrastructure::Compute.new
        expect{ec2_backend_instance.compute_attach_network(networkinterface)}.to raise_exception(Backends::Errors::ResourceNotValidError)
      end

      describe 'regarding public network' do

        let(:compute) {
          ec2_dummy_client.stub_responses(:describe_instances, reservations_stub)
          ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
          ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
          compute = ec2_backend_instance.compute_get("i-22af91c7")
        }
        let(:compute_no_vpc) {
          ec2_dummy_client.stub_responses(:describe_instances, reservations_stub)
          ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
          compute = ec2_backend_instance.compute_get("i-22af91c7")
        }
        let(:network) { ec2_backend_instance.network_get("public") }
        let(:networkinterface) {
          networkinterface = Occi::Infrastructure::Networkinterface.new
          networkinterface.target = network
          networkinterface.source = compute
          networkinterface
        } 
        let(:networkinterface_no_vpc) {
          networkinterface = Occi::Infrastructure::Networkinterface.new
          networkinterface.target = network
          networkinterface.source = compute_no_vpc
          networkinterface
        } 

        it 'attaches "public" network, vpc domain' do
          ec2_dummy_client.stub_responses(:allocate_address, allocation_stub)
          ec2_dummy_client.stub_responses(:associate_address, association_id_stub)
          expect(ec2_backend_instance.compute_attach_network(networkinterface)).to eq "compute_i-5a8cb7bf_nic_eni-0"
        end

        it 'attaches "public" network, standard domain' do
          ec2_dummy_client.stub_responses(:allocate_address, allocation_stub)
          ec2_dummy_client.stub_responses(:associate_address, association_id_stub)
          expect(ec2_backend_instance.compute_attach_network(networkinterface_no_vpc)).to eq "compute_i-5a8cb7bf_nic_eni-0"
        end

        it 'copes with failure on attach, vpc domain' do
          ec2_dummy_client.stub_responses(:allocate_address, allocation_stub)
          ec2_dummy_client.stub_responses(:associate_address, Aws::EC2::Errors::InvalidParameter)
          ec2_dummy_client.stub_responses(:release_address, empty_struct_stub)
          expect{ec2_backend_instance.compute_attach_network(networkinterface)}.to raise_exception(Backends::Errors::ResourceCreationError)
        end

        it 'copes with failure on attach, standard domain' do
          ec2_dummy_client.stub_responses(:allocate_address, allocation_stub)
          ec2_dummy_client.stub_responses(:associate_address, Aws::EC2::Errors::InvalidParameter)
          ec2_dummy_client.stub_responses(:release_address, empty_struct_stub)
          expect{ec2_backend_instance.compute_attach_network(networkinterface_no_vpc)}.to raise_exception(Backends::Errors::ResourceCreationError)
        end

        it 'reports on ellastic IP already attached' do
          ec2_dummy_client.stub_responses(:allocate_address, allocation_stub)
          ec2_dummy_client.stub_responses(:associate_address, association_id_stub)
          ec2_dummy_client.stub_responses(:describe_addresses, addresses_stub)
          expect{ec2_backend_instance.compute_attach_network(networkinterface)}.to raise_exception(Backends::Errors::ResourceCreationError)
        end
      end

      describe 'regarding private network' do
        let(:network) { ec2_backend_instance.network_get("private") }
        let(:compute) {
          ec2_dummy_client.stub_responses(:describe_instances, reservations_stub)
          ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
          ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
          compute = ec2_backend_instance.compute_get("i-22af91c7")
        }
        let(:networkinterface) {
          networkinterface = Occi::Infrastructure::Networkinterface.new
          networkinterface.target = network
          networkinterface.source = compute
          networkinterface
        } 

        it 'reports back correctly as unsupported operation' do
          expect{ec2_backend_instance.compute_attach_network(networkinterface)}.to raise_exception(Backends::Errors::ResourceCreationError)
        end
      end

    end

    describe '.compute_attach_storage' do
      let(:compute) {
        ec2_dummy_client.stub_responses(:describe_instances, reservations_stub)
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        compute = ec2_backend_instance.compute_get("i-22af91c7")
      }
      let(:storage) {
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_backend_instance.storage_get("vol-b42b08b3")
      }

      it 'attaches a volume' do
        storagelink = Occi::Infrastructure::Storagelink.new
        storagelink.source = compute
        storagelink.target = storage

        ec2_dummy_client.stub_responses(:attach_volume, volume_attaching_stub)
        expect(ec2_backend_instance.compute_attach_storage(storagelink)).to eq "compute_i-5a8cb7bf_disk_vol-0b15340c"
      end

      it 'reports correctly on unspecified source' do
        storagelink = Occi::Infrastructure::Storagelink.new
        storagelink.source = compute

        ec2_dummy_client.stub_responses(:attach_volume, volume_attaching_stub)
        expect{ec2_backend_instance.compute_attach_storage(storagelink)}.to raise_exception(Backends::Errors::ResourceNotValidError)
      end

      it 'reports correctly on unspecified target' do
        storagelink = Occi::Infrastructure::Storagelink.new
        storagelink.target = storage

        ec2_dummy_client.stub_responses(:attach_volume, volume_attaching_stub)
        expect{ec2_backend_instance.compute_attach_storage(storagelink)}.to raise_exception(Backends::Errors::ResourceNotValidError)
      end

    end

    describe '.compute_detach_network' do
      context 'regarding vpc' do
        it 'reports unsupported operation when detaching VPC' do
          ec2_dummy_client.stub_responses(:describe_instances, reservations_stub)
          ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
          ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
          ec2_dummy_client.stub_responses(:disassociate_address, empty_struct_stub)
          ec2_dummy_client.stub_responses(:release_address, empty_struct_stub)
          expect{ec2_backend_instance.compute_detach_network("compute_i-5a8cb7bf_nic_eni-7827331d")}.to raise_error(Backends::Errors::ResourceCreationError)
        end
      end

      context 'regarding public network' do
        it 'detaches public network' # TODO: Awaiting Issue#99

      end

      context 'regarding private network' do
        it 'reports unsupported operation when detaching private network' # TODO: Awaiting Issue#99

      end
    end


    describe '.compute_detach_storage' do

      it 'detaches a volume' do
        ec2_dummy_client.stub_responses(:detach_volume, volume_detaching_stub)
        expect(ec2_backend_instance.compute_detach_storage("compute_i-5a8cb7bf_disk_vol-0b15340c")).to be true
      end

      it 'reports correctly on invalid link ID' do
        expect{ec2_backend_instance.compute_detach_storage("invalid")}.to raise_error(Backends::Errors::IdentifierNotValidError)
      end

      it 'reports correctly on non-existent volume' do
        ec2_dummy_client.stub_responses(:detach_volume, Aws::EC2::Errors::InvalidVolumeNotFound)
        expect{ec2_backend_instance.compute_detach_storage("compute_i-5a8cb7bf_disk_vol-0b15340c")}.to raise_error(Backends::Errors::ResourceNotFoundError)
      end

      it 'reports correctly on non-existent instance' do
        ec2_dummy_client.stub_responses(:detach_volume, Aws::EC2::Errors::InvalidInstanceNotFound)
        expect{ec2_backend_instance.compute_detach_storage("compute_i-5a8cb7bf_disk_vol-0b15340c")}.to raise_error(Backends::Errors::ResourceNotFoundError)
      end

      it 'reports correctly on non-existent link' do
        ec2_dummy_client.stub_responses(:detach_volume, Aws::EC2::Errors::IncorrectState)
        expect{ec2_backend_instance.compute_detach_storage("compute_i-5a8cb7bf_disk_vol-0b15340c")}.to raise_error(Backends::Errors::ResourceStateError)
      end

    end

    describe '.compute_get_network' do

      it 'gets a network' do
        ec2_dummy_client.stub_responses(:describe_instances, reservations_stub)
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        expect(ec2_backend_instance.compute_get_network("compute_i-5a8cb7bf_nic_eni-7827331d").id).to eq "compute_i-5a8cb7bf_nic_eni-7827331d"
        expect(ec2_backend_instance.compute_get_network("compute_i-5a8cb7bf_nic_eni-7827331d").source).to eq "/compute/i-5a8cb7bf"
        expect(ec2_backend_instance.compute_get_network("compute_i-5a8cb7bf_nic_eni-7827331d").target).to eq "/network/vpc-7d884a18"
      end

      it 'reports correctly on invalid ID' do
        expect{ec2_backend_instance.compute_get_network("invalid")}.to raise_error (Backends::Errors::IdentifierNotValidError)
      end

      it 'reports correctly on non-existent network' do
        ec2_dummy_client.stub_responses(:describe_instances, reservations_stub)
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        expect{ec2_backend_instance.compute_get_network("compute_i-5a8cb7bf_nic_eni-00000000")}.to raise_error(Backends::Errors::ResourceNotFoundError)
      end

    end

    describe '.compute_get_storage' do
      it 'gets storagelink from ID' do
        ec2_dummy_client.stub_responses(:describe_instances, reservations_storagelink_stub)
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_storagelink_stub)

        storagelink = ec2_backend_instance.compute_get_storage("compute_i-5a8b56be_disk_vol-22574725")

        expect(storagelink.source).to eq "/compute/i-5a8b56be"
        expect(storagelink.target).to eq "/storage/vol-22574725"
      end

      it 'reports non-existent storage link correctly' do
        expect{ec2_backend_instance.compute_get_storage("compute_i-5a8b56be_disk_vol-22574725")}.to raise_error(Backends::Errors::ResourceNotFoundError)
      end

      it 'reports mal-formatted link ID correctly' do
        expect{ec2_backend_instance.compute_get_storage("invalid")}.to raise_error(Backends::Errors::IdentifierNotValidError)
      end
    end

    describe '.compute_trigger_action' do

      it 'triggers "stop" action correctly' do
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_dummy_client.stub_responses(:describe_instances, reservations_stub)
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_dummy_client.stub_responses(:stop_instances, stopping_instances_stub)

        expect(ec2_backend_instance.compute_trigger_action("i-22af91c7",Occi::Core::ActionInstance.new(Occi::Core::Action.new("http://schemas.ogf.org/occi/infrastructure/compute/action#","stop")))).to be true
      end

      it 'triggers "start" action correctly' do
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_dummy_client.stub_responses(:describe_instances, reservations_stopped_stub)
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_dummy_client.stub_responses(:start_instances, starting_instances_stub)

        expect(ec2_backend_instance.compute_trigger_action("i-22af91c7",Occi::Core::ActionInstance.new(Occi::Core::Action.new("http://schemas.ogf.org/occi/infrastructure/compute/action#","start")))).to be true
      end

      it 'triggers "restart" action correctly' do
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_dummy_client.stub_responses(:describe_instances, reservations_stub)
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_dummy_client.stub_responses(:reboot_instances, empty_struct_stub)

        expect(ec2_backend_instance.compute_trigger_action("i-22af91c7",Occi::Core::ActionInstance.new(Occi::Core::Action.new("http://schemas.ogf.org/occi/infrastructure/compute/action#","restart")))).to be true
      end

      it 'returns correctly on unsupported action' do
        attrs = Occi::Core::Attributes.new
        attrs["occi.core.title"] = "test"
        expect{ec2_backend_instance.compute_trigger_action("i-22af91c7",Occi::Core::ActionInstance.new(Occi::Core::Action.new, nil))}.to raise_exception(Backends::Errors::ActionNotImplementedError)
      end

      it 'refuses to perform action in incorrect state' do
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_dummy_client.stub_responses(:describe_instances, reservations_stopped_stub)
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)

        expect{ec2_backend_instance.compute_trigger_action("i-22af91c7",Occi::Core::ActionInstance.new(Occi::Core::Action.new("http://schemas.ogf.org/occi/infrastructure/compute/action#","stop")))}.to raise_error(Backends::Errors::ResourceStateError)

      end
    end

    describe '.compute_trigger_action_on_all' do
      it 'triggers "stop" action correctly' do
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_dummy_client.stub_responses(:describe_instances, reservations_stub)
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_dummy_client.stub_responses(:stop_instances, stopping_instances_stub)

        expect(ec2_backend_instance.compute_trigger_action_on_all(Occi::Core::ActionInstance.new(Occi::Core::Action.new("http://schemas.ogf.org/occi/infrastructure/compute/action#","stop")))).to be true
      end
    end
  end


  context 'network' do

    after(:each) { ec2_backend_instance.instance_variable_set(:@options, default_options) 
                   ec2_backend_instance.instance_variable_set(:@image_filtering_policy, default_image_filtering_policy) }

    describe '.network_create' do
      it 'creates a network instance' do
        ec2_dummy_client.stub_responses(:create_vpc, vpc_stub)
        ec2_dummy_client.stub_responses(:create_subnet, subnet_stub)
        ec2_dummy_client.stub_responses(:create_tags, empty_struct_stub)
        ec2_dummy_client.stub_responses(:create_internet_gateway, internet_gateway_stub)
        ec2_dummy_client.stub_responses(:attach_internet_gateway, empty_struct_stub)

        network = Occi::Infrastructure::Network.new
        network.address='10.0.0.0/24'
        opts=ec2_backend_instance.instance_variable_get(:@options)
        opts.network_create_allowed=true
        ec2_backend_instance.instance_variable_set(:@options, opts)
        expect(ec2_backend_instance.network_create(network)).to eq "vpc-a08b44c5"
      end

      it 'refuses creation on missing permissions' do
        expect{ec2_backend_instance.network_create(Occi::Infrastructure::Network.new)}.to raise_exception(Backends::Errors::UserNotAuthorizedError)
      end

      it 'throws exception if address unspecified' do
        opts=ec2_backend_instance.instance_variable_get(:@options)
        opts.network_create_allowed=true
        ec2_backend_instance.instance_variable_set(:@options, opts)
        expect{ec2_backend_instance.network_create(Occi::Infrastructure::Network.new)}.to raise_exception(Backends::Errors::ResourceNotValidError)
      end
    end

    describe '.network_get' do
      it 'gets network detail' do
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        expect(ec2_backend_instance.network_get("vpc-7d884a18").as_json).to eq expected=YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_samples/network_get.yml")
      end

      it 'gets network detail with network name specified' do
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_w_name_tag_stub)
        expect(ec2_backend_instance.network_get("vpc-7d884a18").attributes.occi.core.title).to eq "Testname"
      end

      it 'gets network detail while offline' do
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_pending_stub)
        expect(ec2_backend_instance.network_get("vpc-7d884a18").attributes.occi.network.state).to eq "offline"
      end
    end

    describe '.network_list_ids' do
      it 'lists network IDs' do
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        expect(ec2_backend_instance.network_list_ids).to eq ["vpc-7d884a18", "public", "private"]
      end
    end

    describe '.network_list' do
      it 'returns network instances' do
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        ids=[]
        list=ec2_backend_instance.network_list.each { |network| ids << network.id }
        expect(ids).to eq ["vpc-7d884a18", "public", "private"]
      end
    end

    describe '.network_delete_all' do
      it 'deletes networks' do
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        ec2_dummy_client.stub_responses(:delete_vpc, true)

        opts=ec2_backend_instance.instance_variable_get(:@options)
        opts.network_destroy_allowed=true
        ec2_backend_instance.instance_variable_set(:@options, opts)

        expect expect(ec2_backend_instance.network_delete_all).to be true
      end
    end

    describe '.network_delete' do
      it 'deletes a network instance' do
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        ec2_dummy_client.stub_responses(:delete_vpc, true)

        opts=ec2_backend_instance.instance_variable_get(:@options)
        opts.network_destroy_allowed=true
        ec2_backend_instance.instance_variable_set(:@options, opts)

        expect(ec2_backend_instance.network_delete("vpc-a08b44c5")).to be true
      end

      it 'copes with operation failing at AWS side' do
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        ec2_dummy_client.stub_responses(:delete_vpc, Aws::EC2::Errors::InvalidVpcIDNotFound)

        opts=ec2_backend_instance.instance_variable_get(:@options)
        opts.network_destroy_allowed=true
        ec2_backend_instance.instance_variable_set(:@options, opts)

        expect{ec2_backend_instance.network_delete("vpc-a08b44c5")}.to raise_exception(Backends::Errors::ResourceNotFoundError)
      end

      it 'refuses deletion on missing permissions' do
        expect{ec2_backend_instance.network_delete("vpc-a08b44c5")}.to raise_exception(Backends::Errors::UserNotAuthorizedError)
      end

      it 'reports correctly on non-existent network' do
        opts=ec2_backend_instance.instance_variable_get(:@options)
        opts.network_destroy_allowed=true
        ec2_backend_instance.instance_variable_set(:@options, opts)

        expect{ec2_backend_instance.network_delete("nonexistent")}.to raise_exception(Backends::Errors::ResourceNotFoundError)
      end

      it 'reports correctly on AWS standard networks' do
        opts=ec2_backend_instance.instance_variable_get(:@options)
        opts.network_destroy_allowed=true
        ec2_backend_instance.instance_variable_set(:@options, opts)

        expect{ec2_backend_instance.network_delete("public")}.to raise_exception(Backends::Errors::UserNotAuthorizedError)
        expect{ec2_backend_instance.network_delete("private")}.to raise_exception(Backends::Errors::UserNotAuthorizedError)
      end

    end

  end

  context 'storage' do
    describe 'storage_list_ids' do
      it 'gets a list of storage resources' do
        ec2_dummy_client.stub_responses(:describe_volume_status, volume_statuses_stub)
        expect(ec2_backend_instance.storage_list_ids).to eq ["vol-b86c67bf", "vol-0d1b100a", "vol-0c1b100b"]
      end
    end

    describe 'storage_list' do
      it 'gets a list of storage resources' do
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        expect(ec2_backend_instance.storage_list.as_json).to eq YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_samples/storage_list.yml")
      end
    end

    describe '.storage_get' do
      it 'gets storage object' do
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        expect(ec2_backend_instance.storage_get("vol-b42b08b3").as_json).to eq YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_samples/storage_get.yml")
      end

      it 'gets storage object with name specified' do
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_w_name_tag_stub)
        expect(ec2_backend_instance.storage_get("vol-b42b08b3").attributes.occi.core.title).to eq "Testname"
      end

      it 'gets network detail while offline' do
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_error_stub)
        expect(ec2_backend_instance.storage_get("vol-b42b08b3").attributes.occi.storage.state).to eq "degraded"
      end
    end

    describe '.storage_create' do
      it 'creates storage with default size (1 GB)' do
        ec2_dummy_client.stub_responses(:create_volume, volume_stub)
        ec2_dummy_client.stub_responses(:create_tags, empty_struct_stub)
        storage = Occi::Infrastructure::Storage.new
        expect(ec2_backend_instance.storage_create(storage)).to eq "vol-b86c67bf"
      end
    end

    describe '.storage_delete' do
      it 'deletes the given storage resource' do
        ec2_dummy_client.stub_responses(:delete_volume, empty_struct_stub)
        expect(ec2_backend_instance.storage_delete("vol-b86c67bf")).to be true
      end
    end

    describe '.storage_delete_all' do
      it 'deletes storage resources' do
        ec2_dummy_client.stub_responses(:describe_volume_status, volume_statuses_stub)
        ec2_dummy_client.stub_responses(:delete_volume, empty_struct_stub)
        expect(ec2_backend_instance.storage_delete_all).to be true
      end
    end

    describe '.storage_trigger_action' do

      it 'triggers "snapshot" action correctly' do
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)

        expect(ec2_backend_instance.storage_trigger_action("vol-b42b08b3",Occi::Core::ActionInstance.new(Occi::Core::Action.new("http://schemas.ogf.org/occi/infrastructure/storage/action#","snapshot")))).to be true
      end

      it 'refuses to trigger action in incorrect state' do
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_deleted_stub)

        expect{ec2_backend_instance.storage_trigger_action("vol-22574725",Occi::Core::ActionInstance.new(Occi::Core::Action.new("http://schemas.ogf.org/occi/infrastructure/storage/action#","snapshot")))}.to raise_error(Backends::Errors::ResourceStateError)
      end

      it 'returns correctly on unsupported action' do
        attrs = Occi::Core::Attributes.new
        attrs["occi.core.title"] = "test"
        expect{ec2_backend_instance.storage_trigger_action("vol-b42b08b3",Occi::Core::ActionInstance.new(Occi::Core::Action.new, nil))}.to raise_exception(Backends::Errors::ActionNotImplementedError)
      end
    end

    describe '.storage_trigger_action_on_all' do
      it 'triggers "snapshot" action correctly' do
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)

        expect(ec2_backend_instance.storage_trigger_action_on_all(Occi::Core::ActionInstance.new(Occi::Core::Action.new("http://schemas.ogf.org/occi/infrastructure/storage/action#","snapshot")))).to be true
      end
    end
  end

  context 'resource_tpl' do
    describe '.resource_tpl_list' do
      it 'gets a list of resource templates' do
        expect(ec2_backend_instance.resource_tpl_list.count).to be > 0
      end
    end

    describe '.resource_tpl_get' do
      it 'gets the given resource template' do
        expect(ec2_backend_instance.resource_tpl_get('t1_micro').location).to eq "/mixin/resource_tpl/t1_micro/"
      end
    end
  end

  context 'os_tpl' do
    describe '.os_tpl_list' do
      it 'gets list of images, not filtered by owner' do
        ec2_dummy_client.stub_responses(:describe_images, images_stub)
        expect(ec2_backend_instance.os_tpl_list.count).to eq 3
      end

      it 'gets list of images, filtered by owner' do
        ec2_dummy_client.stub_responses(:describe_images, images_stub)
        ifpol=ec2_backend_instance.instance_variable_get(:@image_filtering_policy)
        ifpol='only_owned'
        ec2_backend_instance.instance_variable_set(:@image_filtering_policy, ifpol)

        expect(ec2_backend_instance.os_tpl_list.count).to eq 3
      end
    end

    describe '.os_tpl_get' do
      it 'gets template mixin' do
        ec2_dummy_client.stub_responses(:describe_images, images_stub)
        expect(ec2_backend_instance.os_tpl_get("ami-4a5fb53d").as_json).to eq YAML.load_file("spec/lib/backends/ec2_samples/os_tpl_get.yml")
      end
    end
  end


  context 'Unimplemented' do
    # Dummy tests for unimplemented functions, there to:
    #   1)  Complete coverage
    #   2)  Make sure developers are reminded of specs
    #       when the methods are finally implemented :)
    # On implementing, consider moving the spec among the implemented ones
    describe '.network_update' do
      it 'currently returns "Not Supported" message' do
        expect{ec2_backend_instance.network_update(Occi::Infrastructure::Network.new.id)}.to raise_exception(Backends::Errors::MethodNotImplementedError)
      end
    end

    describe '.network_partial_update' do
      it 'currently returns "Not Supported" message' do
        expect{ec2_backend_instance.network_partial_update(Occi::Infrastructure::Network.new.id)}.to raise_exception(Backends::Errors::MethodNotImplementedError)
      end
    end

    describe '.network_trigger_action' do
      it 'currently returns "Not Supported" message' do
        attrs = Occi::Core::Attributes.new
        attrs["occi.core.title"] = "test"
        expect{ec2_backend_instance.network_trigger_action(Occi::Infrastructure::Network.new.id,Occi::Core::ActionInstance.new(Occi::Core::Action.new, nil))}.to raise_exception(Backends::Errors::ActionNotImplementedError)
      end
    end

    describe '.network_trigger_action_on_all' do
      it 'currently returns "Not Supported" message' do
        attrs = Occi::Core::Attributes.new
        attrs["occi.core.title"] = "test"
        expect{ec2_backend_instance.network_trigger_action_on_all(Occi::Core::ActionInstance.new(Occi::Core::Action.new, nil))}.to raise_exception(Backends::Errors::ActionNotImplementedError)
      end
    end

    describe '.storage_partial_update' do
      it 'currently returns "Not Supported" message' do
        expect{ec2_backend_instance.storage_partial_update(Occi::Infrastructure::Storage.new.id)}.to raise_exception(Backends::Errors::MethodNotImplementedError)
      end
    end

    describe '.storage_update' do
      it 'currently returns "Not Supported" message' do
        expect{ec2_backend_instance.storage_update(Occi::Infrastructure::Storage.new.id)}.to raise_exception(Backends::Errors::MethodNotImplementedError)
      end
    end

  end

end
