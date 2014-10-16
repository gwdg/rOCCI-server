require 'spec_helper'

describe AuthenticationStrategies::X509Strategy do
  before(:each) do
    Warden::Strategies.clear!
    AuthenticationStrategies::X509Strategy.send(:remove_const, :OPTIONS) if AuthenticationStrategies::X509Strategy.const_defined?(:OPTIONS)
    AuthenticationStrategies::X509Strategy.const_set(
      :OPTIONS,
      RocciSpecHelpers::YamlHelper.read_yaml("#{File.join(Rails.application.config.rocci_server_etc_dir,'authn_strategies', 'x509', Rails.env + '.yml')}")
    )
    Warden::Strategies.add :x509, AuthenticationStrategies::X509Strategy
  end

  after(:each) do
    Warden::Strategies.clear!
    AuthenticationStrategies::X509Strategy.send(:remove_const, :OPTIONS) if AuthenticationStrategies::X509Strategy.const_defined?(:OPTIONS)
    AuthenticationStrategies::X509Strategy.const_set(
      :OPTIONS,
      RocciSpecHelpers::YamlHelper.read_yaml("#{File.join(Rails.application.config.rocci_server_etc_dir,'authn_strategies', 'x509', Rails.env + '.yml')}")
    )
    # TODO: read the default strategy from Rails.application.config.rocci_server_etc_dir/ENV.yml
    Warden::Strategies.add :dummy, AuthenticationStrategies::DummyStrategy
  end

  let(:strategy){ Warden::Strategies[:x509].new(Warden::Test::StrategyHelper.env_with_params) }
  let(:valid_x509) do
    { 
      "SSL_CLIENT_S_DN" => "/DC=cz/DC=cesnet-ca/O=CESNET/CN=Boris Parak",
      "SSL_CLIENT_I_DN" => "/DC=cz/DC=cesnet-ca/O=CESNET CA/CN=CESNET CA 3",
      "SSL_CLIENT_VERIFY" => "SUCCESS"
    }
  end
  let(:invalid_x509) do
    {
      "SSL_CLIENT_S_DN" => "/DC=cz/DC=cesnet-ca/O=CESNET/CN=Boris Parak",
      "SSL_CLIENT_I_DN" => "/DC=cz/DC=cesnet-ca/O=CESNET CA/CN=CESNET CA 3",
      "SSL_CLIENT_VERIFY" => "FAILURE"
    }
  end
  let(:strategy_w_x509){ Warden::Strategies[:x509].new(Warden::Test::StrategyHelper.env_with_params('/', {}, valid_x509)) }
  let(:strategy_w_invalid_x509){ Warden::Strategies[:x509].new(Warden::Test::StrategyHelper.env_with_params('/', {}, invalid_x509)) }

  describe "implements required methods" do

    it "responds to valid?" do
      expect(strategy).to respond_to :valid?
    end

    it "is not valid without SSL_CLIENT_S_DN header present" do
      expect(strategy.valid?).to be false
    end

    it "is valid with SSL_CLIENT_S_DN header present" do
      expect(strategy_w_x509.valid?).to be true
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

  describe "with SSL_CLIENT_* headers set" do

    it "sets a user" do
      strategy_w_x509._run!
      expect(strategy_w_x509.user).not_to eq nil
    end

    it "sets expected values for credentials" do
      strategy_w_x509._run!

      expect(strategy_w_x509.user.auth!.type).to eq 'x509'
      expect(strategy_w_x509.user.auth!.credentials!.client_cert_dn).to eq valid_x509['SSL_CLIENT_S_DN']
      expect(strategy_w_x509.user.auth!.credentials!.client_cert).to eq valid_x509['SSL_CLIENT_CERT'] unless valid_x509['SSL_CLIENT_CERT'].blank?
      expect(strategy_w_x509.user.auth!.credentials!.issuer_cert_dn).to eq valid_x509['SSL_CLIENT_I_DN']
      expect(strategy_w_x509.user.auth!.credentials!.verification_status).to eq valid_x509['SSL_CLIENT_VERIFY']
      expect(strategy_w_x509.user.identity).to eq valid_x509['SSL_CLIENT_S_DN']
    end

    it "reports a success" do
      strategy_w_x509._run!
      expect(strategy_w_x509.result).to be :success
    end

  end

  describe "with invalid SSL_CLIENT_* headers set" do

    it "halts the strategies when failing" do
      strategy_w_invalid_x509._run!
      expect(strategy_w_invalid_x509).to be_halted
    end

    it "allows you to set a message when failing" do
      strategy_w_invalid_x509._run!
      expect(strategy_w_invalid_x509.message).to eq "The verification process has failed! SSL_CLIENT_VERIFY = #{invalid_x509['SSL_CLIENT_VERIFY'].inspect}"
    end

    it "reports a failure" do
      strategy_w_invalid_x509._run!
      expect(strategy_w_invalid_x509.result).to be :failure
    end

  end

end
