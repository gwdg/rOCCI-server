require 'spec_helper'

describe AuthenticationStrategies::DummyStrategy do
  before(:each) do
    Warden::Strategies.clear!
    AuthenticationStrategies::DummyStrategy.send(:remove_const, :OPTIONS) if AuthenticationStrategies::DummyStrategy.const_defined?(:OPTIONS)
    AuthenticationStrategies::DummyStrategy.const_set(
      :OPTIONS,
      RocciSpecHelpers::YamlHelper.read_yaml("#{File.join(Rails.application.config.rocci_server_etc_dir,'authn_strategies', 'dummy', Rails.env + '.yml')}")
    )
    Warden::Strategies.add :dummy, AuthenticationStrategies::DummyStrategy
  end

  after(:each) do
    Warden::Strategies.clear!
    AuthenticationStrategies::DummyStrategy.send(:remove_const, :OPTIONS) if AuthenticationStrategies::DummyStrategy.const_defined?(:OPTIONS)
    AuthenticationStrategies::DummyStrategy.const_set(
      :OPTIONS,
      RocciSpecHelpers::YamlHelper.read_yaml("#{File.join(Rails.application.config.rocci_server_etc_dir,'authn_strategies', 'dummy', Rails.env + '.yml')}")
    )
    # TODO: read the default strategy from Rails.application.config.rocci_server_etc_dir/ENV.yml
    Warden::Strategies.add :dummy, AuthenticationStrategies::DummyStrategy
  end

  let(:strategy){ Warden::Strategies[:dummy].new(Warden::Test::StrategyHelper.env_with_params) }

  describe "implements required methods" do

    it "responds to valid?" do
      expect(strategy).to respond_to :valid?
    end

    it "is always valid" do
      expect(strategy.valid?).to be true
    end

    it "responds to store?" do
      expect(strategy).to respond_to :store?
    end

    it "is never stored" do
      expect(strategy.store?).to be false
    end

    it "responds to authenticate!" do
      expect(strategy).to respond_to :authenticate!
    end

  end

  describe "works with defaults" do

    it "sets a user" do
      strategy._run!
      expect(strategy.user).not_to eq nil
    end

    it "sets expected default values for dummy user" do
      strategy._run!

      expect(strategy.user.auth!.type).to eq 'basic'
      expect(strategy.user.auth!.credentials!.username).to eq 'dummy_user'
      expect(strategy.user.auth!.credentials!.password).to eq 'dummy_password'
      expect(strategy.user.identity).to eq 'dummy_user'
    end

    it "reports a success" do
      strategy._run!
      expect(strategy.result).to be :success
    end

  end

  describe "respects OPTIONS" do

    it "fakes x509 when requested" do
      strategy.class::OPTIONS.fake_type = 'x509'
      strategy._run!

      expect(strategy.user.auth!.type).to eq 'x509'
      expect(strategy.user.auth!.credentials!.client_cert_dn).to eq 'dummy_cert_dn'
      expect(strategy.user.auth!.credentials!.client_cert).to eq 'dummy_cert'
      expect(strategy.user.auth!.credentials!.client_cert_voms_attrs).to eq({})
      expect(strategy.user.auth!.credentials!.issuer_cert_dn).to eq 'dummy_issuer_cert_dn'
      expect(strategy.user.auth!.credentials!.verification_status).to eq 'SUCCESS'
      expect(strategy.user.identity).to eq 'dummy_cert_dn'
    end

    it "fakes voms when requested" do
      strategy.class::OPTIONS.fake_type = 'voms'
      strategy._run!

      expect(strategy.user.auth!.type).to eq 'voms'
      expect(strategy.user.auth!.credentials!.client_cert_dn).to eq 'dummy_cert_dn'
      expect(strategy.user.auth!.credentials!.client_cert).to eq 'dummy_cert'
      expect(strategy.user.auth!.credentials!.client_cert_voms_attrs).to eq({})
      expect(strategy.user.auth!.credentials!.issuer_cert_dn).to eq 'dummy_issuer_cert_dn'
      expect(strategy.user.auth!.credentials!.verification_status).to eq 'SUCCESS'
      expect(strategy.user.identity).to eq 'dummy_cert_dn'
    end

    it "fakes basic when requested" do
      strategy.class::OPTIONS.fake_type = 'basic'
      strategy._run!

      expect(strategy.user.auth!.type).to eq 'basic'
      expect(strategy.user.auth!.credentials!.username).to eq 'dummy_user'
      expect(strategy.user.auth!.credentials!.password).to eq 'dummy_password'
      expect(strategy.user.identity).to eq 'dummy_user'
    end

    it "returns empty credentials for unknown auth type" do
      strategy.class::OPTIONS.fake_type = 'stupid'
      strategy._run!

      expect(strategy.user.auth!.type).to eq 'stupid'
      expect(strategy.user.auth!.credentials).to eq({})
      expect(strategy.user.identity).to eq 'unknown'
    end

    it "fails when block_all is enabled" do
      strategy.class::OPTIONS.block_all = true
      strategy._run!
      expect(strategy.user).to eq nil
    end

    it "halts the strategies when failing" do
      strategy.class::OPTIONS.block_all = true
      strategy._run!
      expect(strategy).to be_halted
    end

    it "allows you to set a message when failing" do
      strategy.class::OPTIONS.block_all = true
      strategy._run!
      expect(strategy.message).to eq "BlockAll for DummyStrategy is active!"
    end

    it "reports a failure" do
      strategy.class::OPTIONS.block_all = true
      strategy._run!
      expect(strategy.result).to be :failure
    end

  end
end
