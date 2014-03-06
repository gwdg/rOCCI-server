require 'spec_helper'

describe AuthenticationStrategies::DummyStrategy do
  before(:each) do
    Warden::Strategies.clear!
    AuthenticationStrategies::DummyStrategy.send(:remove_const, :OPTIONS) if AuthenticationStrategies::DummyStrategy.const_defined?(:OPTIONS)
    AuthenticationStrategies::DummyStrategy.const_set(:OPTIONS, Hashie::Mash.new)
    Warden::Strategies.add :dummy, AuthenticationStrategies::DummyStrategy
  end

  describe "works with defaults" do

    it "sets a user" do
      strategy = Warden::Strategies[:dummy].new(Warden::Test::StrategyHelper.env_with_params)
      strategy._run!
      expect(strategy.user).not_to eq nil
    end

    it "sets expected default values for dummy user" do
      strategy = Warden::Strategies[:dummy].new(Warden::Test::StrategyHelper.env_with_params)
      strategy._run!

      expect(strategy.user.auth!.type).to eq 'dummy'
      expect(strategy.user.auth!.credentials!.username).to eq 'dummy_user'
      expect(strategy.user.auth!.credentials!.password).to eq 'dummy_password'
    end

  end

  describe "respects OPTIONS" do

    it "fakes x509 when requested" do
      strategy = Warden::Strategies[:dummy].new(Warden::Test::StrategyHelper.env_with_params)
      strategy.class::OPTIONS.fake_type = 'x509'
      strategy._run!

      expect(strategy.user.auth!.type).to eq 'x509'
      expect(strategy.user.auth!.credentials!.client_cert_dn).to eq 'dummy_cert_dn'
      expect(strategy.user.auth!.credentials!.client_cert).to eq 'dummy_cert'
      expect(strategy.user.auth!.credentials!.client_cert_voms_attrs).to eq({})
      expect(strategy.user.auth!.credentials!.issuer_cert_dn).to eq 'dummy_issuer_cert_dn'
      expect(strategy.user.auth!.credentials!.verification_status).to eq 'SUCCESS'
    end

    it "fakes voms when requested" do
      strategy = Warden::Strategies[:dummy].new(Warden::Test::StrategyHelper.env_with_params)
      strategy.class::OPTIONS.fake_type = 'voms'
      strategy._run!

      expect(strategy.user.auth!.type).to eq 'voms'
      expect(strategy.user.auth!.credentials!.client_cert_dn).to eq 'dummy_cert_dn'
      expect(strategy.user.auth!.credentials!.client_cert).to eq 'dummy_cert'
      expect(strategy.user.auth!.credentials!.client_cert_voms_attrs).to eq({})
      expect(strategy.user.auth!.credentials!.issuer_cert_dn).to eq 'dummy_issuer_cert_dn'
      expect(strategy.user.auth!.credentials!.verification_status).to eq 'SUCCESS'
    end

    it "fakes basic when requested" do
      strategy = Warden::Strategies[:dummy].new(Warden::Test::StrategyHelper.env_with_params)
      strategy.class::OPTIONS.fake_type = 'basic'
      strategy._run!

      expect(strategy.user.auth!.type).to eq 'basic'
      expect(strategy.user.auth!.credentials!.username).to eq 'dummy_user'
      expect(strategy.user.auth!.credentials!.password).to eq 'dummy_password'
    end

    it "returns empty credentials for unknown auth type" do
      strategy = Warden::Strategies[:dummy].new(Warden::Test::StrategyHelper.env_with_params)
      strategy.class::OPTIONS.fake_type = 'stupid'
      strategy._run!

      expect(strategy.user.auth!.type).to eq 'stupid'
      expect(strategy.user.auth!.credentials).to eq({})
    end

    it "fails when block_all is enabled" do
      strategy = Warden::Strategies[:dummy].new(Warden::Test::StrategyHelper.env_with_params)
      strategy.class::OPTIONS.block_all = true
      strategy._run!
      expect(strategy.user).to eq nil
    end

  end
end
