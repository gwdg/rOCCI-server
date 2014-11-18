require 'spec_helper'
require 'yaml'

describe Backends::Ec2Backend do
  let(:dalli) { Dalli::Client.new }
  let(:aws_creds) { ::Aws::Credentials.new('a', 'b') }
  let(:ec2_dummy_client) { ::Aws::EC2::Client.new(credentials: aws_creds, stub_responses: true) }
  let(:instance_statuses_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/instance_statuses_stub.yml") }
  let(:reservations_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/reservations_stub.yml") }
  let(:volumes_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/volumes_stub.yml") }
  let(:vpcs_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/vpcs_stub.yml") }
  let(:ec2_backend_instance) do
    instance = Backends::Ec2Backend.new nil, nil, nil, nil, dalli
    instance.instance_variable_set(:@ec2_client, ec2_dummy_client)

    instance
  end

  before(:each) { dalli.flush }
  after(:all) { Dalli::Client.new.flush }

  context 'compute' do
    describe 'compute_list_ids' do
      it 'runs with empty list' do
        expect(ec2_backend_instance.compute_list_ids).to eq([])
      end

      it 'Receives compute instance list correctly' do
        ec2_dummy_client.stub_responses(:describe_instance_status, instance_statuses:instance_statuses_stub)
        expect(ec2_backend_instance.compute_list_ids).to eq(["ID", "ID2"])
      end
    end

    describe '.compute_list' do
      it 'runs with empty list' do
        expect(ec2_backend_instance.compute_list).to eq([])
      end

      it 'Receives compute instance list correctly with nil storage and vpcs description' do
        ec2_dummy_client.stub_responses(:describe_instances, reservations_stub)
        returned = ""
        ec2_backend_instance.compute_list.each { |resource| returned = "#{returned}#{resource.to_text}\n" }

        expected = File.open("spec/lib/backends/ec2_samples/compute_list_no_links.expected","rt").read
        
        expect(returned).to eq expected
      end

      it 'Receives compute instance list correctly' do
        ec2_dummy_client.stub_responses(:describe_instances, reservations_stub)
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        ec2_dummy_client.stub_responses(:describe_vpcs, vpcs_stub)
        returned = ""
        ec2_backend_instance.compute_list.each { |resource| returned = "#{returned}#{resource.to_text}\n" }

        expected = File.open("spec/lib/backends/ec2_samples/compute_list.expected","rt").read
        
        expect(returned).to eq expected
      end
    end

    describe '.compute_get' do
      it 'copes with non-existent id' do
        expect(ec2_backend_instance.compute_get("someID")).to eq nil
      end

      it 'gets compute instance description correctly' do
        ec2_dummy_client.stub_responses(:describe_instances, reservations_stub)
        returned = ec2_backend_instance.compute_get("i-22af91c7").to_text
        expected = expected = File.open("spec/lib/backends/ec2_samples/compute_list_single_instance.expected","rt").read
        expect(returned).to eq expected
      end
    end

    describe '.compute_create' do
      it 'reports correctly on missing os_tpl mixin' do
        compute = Occi::Infrastructure::Compute.new
        expect{ec2_backend_instance.compute_create(compute)}.to raise_exception(Backends::Errors::ResourceNotValidError)
      end

      it 'creates compute resource correctyly' do
        ostemplate = Occi::Core::Mixin.new("http://occi.localhost/occi/infrastructure/os_tpl#", "ami-6e7bd919")
        ostemplate.depends=["http://schemas.ogf.org/occi/infrastructure#os_tpl"]
        compute = Occi::Infrastructure::Compute.new
        compute.mixins << ostemplate
        expect(ec2_backend_instance.compute_create(compute)).to eq []
      end
    end
  end

end
