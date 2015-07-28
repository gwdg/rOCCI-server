require 'spec_helper'
require 'yaml'
require Rails.root.join('spec/lib/backends/ec2/test_env')

describe Backends::Ec2::Network do
##
  let(:dalli) { Dalli::Client.new }
  before(:each) { dalli.flush }
  after(:all) { Dalli::Client.new.flush }

##
  let(:aws_creds) { ::Aws::Credentials.new('a', 'b') }
  let(:ec2_dummy_client) { ::Aws::EC2::Client.new(credentials: aws_creds, stub_responses: true) }

##
  let(:instance_statuses_stub) { YAML.load_file("#{EC2_STUBS_DIR}/instance_statuses_stub.yml") }

##
  let(:reservations_stub) { YAML.load_file("#{EC2_STUBS_DIR}/reservations_stub.yml") }
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
  let(:reservation_stub) { YAML.load_file("#{EC2_STUBS_DIR}/reservation_stub.yml") }
  let(:reservations_storagelink_stub) { YAML.load_file("#{EC2_STUBS_DIR}/reservations_storagelink_stub.yml") }
  let(:reservations_stopped_stub) { YAML.load_file("#{EC2_STUBS_DIR}/reservations_stopped_stub.yml") }

##
  let(:volumes_stub) { YAML.load_file("#{EC2_STUBS_DIR}/volumes_stub.yml") }
  let(:volumes_w_name_tag_stub) { volumes = volumes_stub
  volumes[:volumes].each { |vol| vol[:tags] = [ {:key => "Name", :value => "Testname"} ] }
  volumes }
  let(:volumes_error_stub) { volumes = volumes_stub
  volumes[:volumes].each { |vol| vol[:state] = "error" }
  volumes }
  let(:volumes_storagelink_stub) { YAML.load_file("#{EC2_STUBS_DIR}/volumes_storagelink_stub.yml") }
  let(:volumes_deleted_stub) { YAML.load_file("#{EC2_STUBS_DIR}/volumes_deleted_stub.yml") }
  let(:volume_stub) { YAML.load_file("#{EC2_STUBS_DIR}/volume_stub.yml") }
  let(:volume_statuses_stub) { YAML.load_file("#{EC2_STUBS_DIR}/volume_statuses_stub.yml") }
  let(:volume_attaching_stub) { YAML.load_file("#{EC2_STUBS_DIR}/volume_attaching_stub.yml") }
  let(:volume_detaching_stub) { YAML.load_file("#{EC2_STUBS_DIR}/volume_detaching_stub.yml") }

##
  let(:vpcs_stub) { YAML.load_file("#{EC2_STUBS_DIR}/vpcs_stub.yml") }
  let(:vpcs_w_name_tag_stub) { vpcs = vpcs_stub
  vpcs[:vpcs].first[:tags] = [ {:key => "Name", :value => "Testname"} ]
  vpcs }
  let(:vpcs_pending_stub) { vpcs = vpcs_stub
  vpcs[:vpcs].first[:state] = "pending"
  vpcs }
  let(:vpc_stub) { YAML.load_file("#{EC2_STUBS_DIR}/vpc_stub.yml") }

##
  let(:subnet_stub) { YAML.load_file("#{EC2_STUBS_DIR}/subnet_stub.yml") }
  let(:subnets_stub) { { :subnets => [ subnet_stub[:subnet] ] } }

##
  let(:empty_struct_stub) { YAML.load_file("#{EC2_STUBS_DIR}/empty_struct_stub.yml") }
  let(:internet_gateway_stub) { YAML.load_file("#{EC2_STUBS_DIR}/internet_gateway_stub.yml") }
  let(:terminating_instances_stub) { YAML.load_file("#{EC2_STUBS_DIR}/terminating_instances_stub.yml") }
  let(:terminating_instances_single_stub) { YAML.load_file("#{EC2_STUBS_DIR}/terminating_instances_single_stub.yml") }

##
  let(:images_stub) { YAML.load_file("#{EC2_STUBS_DIR}/images_stub.yml") }
  let(:association_id_stub) { YAML.load_file("#{EC2_STUBS_DIR}/association_id_stub.yml") }
  let(:allocation_stub) { YAML.load_file("#{EC2_STUBS_DIR}/allocation_stub.yml") }
  let(:addresses_stub) { YAML.load_file("#{EC2_STUBS_DIR}/addresses_stub.yml") }
  let(:stopping_instances_stub) { YAML.load_file("#{EC2_STUBS_DIR}/stopping_instances_stub.yml") }
  let(:starting_instances_stub) { YAML.load_file("#{EC2_STUBS_DIR}/starting_instances_stub.yml") }

##
  let(:ec2_backend_delegated_user) do
    user = Hashie::Mash.new
    user.identity = "dummy_test_user"
    user
  end
  let(:ec2_backend_compute) do
    options = YAML.load(ERB.new(File.read("#{Rails.root}/etc/backends/ec2/test.yml")).result)
    instance = Backends::Ec2::Compute.new(ec2_backend_delegated_user, options, nil, nil, dalli)
    instance.instance_variable_set(:@ec2_client, ec2_dummy_client)
    instance
  end
  let(:ec2_backend_network) do
    options = YAML.load(ERB.new(File.read("#{Rails.root}/etc/backends/ec2/test.yml")).result)
    instance = Backends::Ec2::Network.new(ec2_backend_delegated_user, options, nil, nil, dalli)
    instance.instance_variable_set(:@ec2_client, ec2_dummy_client)
    instance
  end
  let(:ec2_backend_storage) do
    options = YAML.load(ERB.new(File.read("#{Rails.root}/etc/backends/ec2/test.yml")).result)
    instance = Backends::Ec2::Storage.new(ec2_backend_delegated_user, options, nil, nil, dalli)
    instance.instance_variable_set(:@ec2_client, ec2_dummy_client)
    instance
  end
  let(:ec2_backend_instance) do
    instance = ec2_backend_network
    instance.add_other_backend('storage', ec2_backend_storage)
    instance.add_other_backend('compute', ec2_backend_compute)
    instance
  end

##
  let(:default_options) { ec2_backend_instance.instance_variable_get(:@options) }
  let(:default_image_filtering_policy) { ec2_backend_instance.instance_variable_get(:@image_filtering_policy) }

  context 'network' do
    after(:each) { ec2_backend_instance.instance_variable_set(:@options, default_options) 
                   ec2_backend_instance.instance_variable_set(:@image_filtering_policy, default_image_filtering_policy) }

    describe '.create' do
      it 'creates a network instance' do
        ec2_dummy_client.stub_responses(:create_vpc, vpc_stub)
        ec2_dummy_client.stub_responses(:create_subnet, subnet_stub)
        ec2_dummy_client.stub_responses(:create_tags, empty_struct_stub)
        ec2_dummy_client.stub_responses(:create_internet_gateway, internet_gateway_stub)
        ec2_dummy_client.stub_responses(:attach_internet_gateway, empty_struct_stub)

        network = Occi::Infrastructure::Network.new
        network.address = '10.0.0.0/24'
        opts = ec2_backend_instance.instance_variable_get(:@options)
        opts.network_create_allowed = true
        ec2_backend_instance.instance_variable_set(:@options, opts)
        expect(ec2_backend_instance.create(network)).to eq "vpc-a08b44c5"
      end

      it 'refuses creation on missing permissions' do
        expect{ec2_backend_instance.create(Occi::Infrastructure::Network.new)}.to raise_exception(Backends::Errors::UserNotAuthorizedError)
      end

      it 'throws exception if address unspecified' do
        opts = ec2_backend_instance.instance_variable_get(:@options)
        opts.network_create_allowed = true
        ec2_backend_instance.instance_variable_set(:@options, opts)
        expect{ec2_backend_instance.create(Occi::Infrastructure::Network.new)}.to raise_exception(Backends::Errors::ResourceNotValidError)
      end
    end

    describe '.get' do
      it 'gets network detail' do
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        expect(ec2_backend_instance.get("vpc-7d884a18").as_json).to eq expected=YAML.load_file("#{EC2_SAMPLES_DIR}/network_get.yml")
      end

      it 'gets network detail with network name specified' do
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_w_name_tag_stub)
        expect(ec2_backend_instance.get("vpc-7d884a18").attributes.occi.core.title).to eq "Testname"
      end

      it 'gets network detail while offline' do
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_pending_stub)
        expect(ec2_backend_instance.get("vpc-7d884a18").attributes.occi.network.state).to eq "offline"
      end
    end

    describe '.list_ids' do
      it 'lists network IDs' do
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        expect(ec2_backend_instance.list_ids).to eq ["vpc-7d884a18", "public", "private"]
      end
    end

    describe '.list' do
      it 'returns network instances' do
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        ids=[]
        list=ec2_backend_instance.list.each { |network| ids << network.id }
        expect(ids).to eq ["vpc-7d884a18", "public", "private"]
      end
    end

    describe '.delete_all' do
      it 'deletes networks' do
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        ec2_dummy_client.stub_responses(:delete_vpc, true)

        opts = ec2_backend_instance.instance_variable_get(:@options)
        opts.network_destroy_allowed = true
        ec2_backend_instance.instance_variable_set(:@options, opts)

        expect expect(ec2_backend_instance.delete_all).to be true
      end
    end

    describe '.delete' do
      it 'deletes a network instance' do
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        ec2_dummy_client.stub_responses(:delete_vpc, true)

        opts = ec2_backend_instance.instance_variable_get(:@options)
        opts.network_destroy_allowed = true
        ec2_backend_instance.instance_variable_set(:@options, opts)

        expect(ec2_backend_instance.delete("vpc-a08b44c5")).to be true
      end

      it 'copes with operation failing at AWS side' do
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        ec2_dummy_client.stub_responses(:delete_vpc, Aws::EC2::Errors::InvalidVpcIDNotFound.new(Seahorse::Client::RequestContext.new,"VPC does not exist"))

        opts = ec2_backend_instance.instance_variable_get(:@options)
        opts.network_destroy_allowed = true
        ec2_backend_instance.instance_variable_set(:@options, opts)

        expect{ec2_backend_instance.delete("vpc-a08b44c5")}.to raise_exception(Backends::Errors::ResourceNotFoundError)
      end

      it 'refuses deletion on missing permissions' do
        expect{ec2_backend_instance.delete("vpc-a08b44c5")}.to raise_exception(Backends::Errors::UserNotAuthorizedError)
      end

      it 'reports correctly on non-existent network' do
        opts = ec2_backend_instance.instance_variable_get(:@options)
        opts.network_destroy_allowed = true
        ec2_backend_instance.instance_variable_set(:@options, opts)

        expect{ec2_backend_instance.delete("nonexistent")}.to raise_exception(Backends::Errors::ResourceNotFoundError)
      end

      it 'reports correctly on AWS standard networks' do
        opts = ec2_backend_instance.instance_variable_get(:@options)
        opts.network_destroy_allowed = true
        ec2_backend_instance.instance_variable_set(:@options, opts)

        expect{ec2_backend_instance.delete("public")}.to raise_exception(Backends::Errors::UserNotAuthorizedError)
        expect{ec2_backend_instance.delete("private")}.to raise_exception(Backends::Errors::UserNotAuthorizedError)
      end
    end
  end

  context 'Unimplemented' do
    # Dummy tests for unimplemented functions, there to:
    #   1)  Complete coverage
    #   2)  Make sure developers are reminded of specs
    #       when the methods are finally implemented :)
    # On implementing, consider moving the spec among the implemented ones
    describe '.update' do
      it 'currently returns "Not Supported" message' do
        expect{ec2_backend_instance.update(Occi::Infrastructure::Network.new.id)}.to raise_exception(Backends::Errors::MethodNotImplementedError)
      end
    end

    describe '.partial_update' do
      it 'currently returns "Not Supported" message' do
        expect{ec2_backend_instance.partial_update(Occi::Infrastructure::Network.new.id)}.to raise_exception(Backends::Errors::MethodNotImplementedError)
      end
    end

    describe '.trigger_action' do
      it 'currently returns "Not Supported" message' do
        attrs = Occi::Core::Attributes.new
        attrs["occi.core.title"] = "test"
        expect{ec2_backend_instance.trigger_action(Occi::Infrastructure::Network.new.id,Occi::Core::ActionInstance.new(Occi::Core::Action.new, nil))}.to raise_exception(Backends::Errors::ActionNotImplementedError)
      end
    end

    describe '.trigger_action_on_all' do
      it 'currently returns "Not Supported" message' do
        attrs = Occi::Core::Attributes.new
        attrs["occi.core.title"] = "test"
        expect{ec2_backend_instance.trigger_action_on_all(Occi::Core::ActionInstance.new(Occi::Core::Action.new, nil))}.to raise_exception(Backends::Errors::ActionNotImplementedError)
      end
    end
  end
end
