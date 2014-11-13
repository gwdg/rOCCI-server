require 'spec_helper'
require 'yaml'

describe Backends::Ec2Backend do
  let(:dalli) { Dalli::Client.new }
  let(:aws_creds) { ::Aws::Credentials.new('a', 'b') }
  let(:ec2_dummy_client) { ::Aws::EC2::Client.new(credentials: aws_creds, stub_responses: true) }
  let(:instance_statuses_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/instance_statuses_stub.yml") }
  let(:reservations_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/reservations_stub.yml") }
  let(:volumes_stub) { YAML.load_file("#{Rails.root}/spec/lib/backends/ec2_stubs/volumes_stub.yml") }
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

      it 'Receives compute instance list correctly with nil storage description' #do
#        ec2_dummy_client.stub_responses(:describe_instances, reservations_stub)
#        expect(ec2_backend_instance.compute_list).to eq(["ID", "ID2"])
#      end

      it 'Receives compute instance list correctly' do
        ec2_dummy_client.stub_responses(:describe_instances, reservations_stub)
        ec2_dummy_client.stub_responses(:describe_volumes, volumes_stub)
        expect(ec2_backend_instance.compute_list).to eq(["ID", "ID2"])
      end
    end
  end

end
