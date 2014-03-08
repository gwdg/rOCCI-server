require 'spec_helper'

describe AuthenticationStrategies::VomsStrategy do
  before(:each) do
    Warden::Strategies.clear!
    AuthenticationStrategies::VomsStrategy.send(:remove_const, :OPTIONS) if AuthenticationStrategies::VomsStrategy.const_defined?(:OPTIONS)
    AuthenticationStrategies::VomsStrategy.const_set(
      :OPTIONS,
      RocciSpecHelpers::YamlHelper.read_yaml("#{Rails.root.join('etc','authn_strategies', 'voms', Rails.env + '.yml')}")
    )
    Warden::Strategies.add :voms, AuthenticationStrategies::VomsStrategy
  end

  after(:each) do
    Warden::Strategies.clear!
    AuthenticationStrategies::VomsStrategy.send(:remove_const, :OPTIONS) if AuthenticationStrategies::VomsStrategy.const_defined?(:OPTIONS)
    AuthenticationStrategies::VomsStrategy.const_set(
      :OPTIONS,
      RocciSpecHelpers::YamlHelper.read_yaml("#{Rails.root.join('etc','authn_strategies', 'voms', Rails.env + '.yml')}")
    )
    # TODO: read the default strategy from Rails.root/etc/Rails.env.yml
    Warden::Strategies.add :dummy, AuthenticationStrategies::DummyStrategy
  end

  let(:strategy){ Warden::Strategies[:voms].new(Warden::Test::StrategyHelper.env_with_params) }
  let(:valid_voms) do
    { 
      "SSL_CLIENT_S_DN" => "/DC=cz/DC=cesnet-ca/O=CESNET/CN=Boris Parak",
      "SSL_CLIENT_I_DN" => "/DC=cz/DC=cesnet-ca/O=CESNET CA/CN=CESNET CA 3",
      "SSL_CLIENT_VERIFY" => "SUCCESS",
      "GRST_CRED_0" => "X509USER 1341878400 1376092799 1 /DC=cz/DC=cesnet-ca/O=CESNET/CN=Boris Parak",
      "GRST_CRED_1" => "GSIPROXY 1354921680 1354965180 1 /DC=cz/DC=cesnet-ca/O=CESNET/CN=Boris Parak/CN=447432737",
      "GRST_CRED_2" => "VOMS 140365809703311 1354965180 0 /vo.example.org/Role=NULL/Capability=NULL"
    }
  end
  let(:invalid_voms) do
    {
      "SSL_CLIENT_S_DN" => "/DC=cz/DC=cesnet-ca/O=CESNET/CN=Boris Parak",
      "SSL_CLIENT_I_DN" => "/DC=cz/DC=cesnet-ca/O=CESNET CA/CN=CESNET CA 3",
      "SSL_CLIENT_VERIFY" => "FAILURE",
      "GRST_CRED_0" => "X509USER 1341878400 1376092799 1 /DC=cz/DC=cesnet-ca/O=CESNET/CN=Boris Parak",
      "GRST_CRED_1" => "GSIPROXY 1354921680 1354965180 1 /DC=cz/DC=cesnet-ca/O=CESNET/CN=Boris Parak/CN=447432737",
      "GRST_CRED_2" => "VOMS 140365809703311 1354965180 MALFORMED /vo.example.org/Role=NULL/Capability=NULL"
    }
  end
  let(:invalid_voms2) do
    {
      "SSL_CLIENT_S_DN" => "/DC=cz/DC=cesnet-ca/O=CESNET/CN=Boris Parak",
      "SSL_CLIENT_I_DN" => "/DC=cz/DC=cesnet-ca/O=CESNET CA/CN=CESNET CA 3",
      "SSL_CLIENT_VERIFY" => "FAILURE",
      "GRST_CRED_0" => "X509USER 1341878400 1376092799 MALFORMED /DC=cz/DC=cesnet-ca/O=CESNET/CN=Boris Parak",
      "GRST_CRED_1" => "GSIPROXY 1354921680 1354965180 1 /DC=cz/DC=cesnet-ca/O=CESNET/CN=Boris Parak/CN=447432737",
      "GRST_CRED_2" => "VOMS 140365809703311 1354965180 0 /vo.example.org/Role=NULL/Capability=NULL"
    }
  end
  let(:strategy_w_voms){ Warden::Strategies[:voms].new(Warden::Test::StrategyHelper.env_with_params('/', {}, valid_voms)) }
  let(:strategy_w_invalid_voms){ Warden::Strategies[:voms].new(Warden::Test::StrategyHelper.env_with_params('/', {}, invalid_voms)) }
  let(:strategy_w_invalid_voms2){ Warden::Strategies[:voms].new(Warden::Test::StrategyHelper.env_with_params('/', {}, invalid_voms2)) }

  describe "implements required methods" do

    it "responds to valid?" do
      expect(strategy).to respond_to :valid?
    end

    it "is not valid without SSL_CLIENT_S_DN and GRST_CRED_* headers present" do
      expect(strategy.valid?).to be_false
    end

    it "is valid with SSL_CLIENT_S_DN and GRST_CRED_* headers present" do
      expect(strategy_w_voms.valid?).to be_true
    end

    it "responds to store?" do
      expect(strategy).to respond_to :store?
    end

    it "is never stored" do
      expect(strategy.store?).to be_false
    end

    it "responds to authenticate!" do
      expect(strategy).to respond_to :authenticate!
    end

  end

  describe "with SSL_CLIENT_* and GRST_CRED_* headers set" do

    it "sets a user" do
      strategy_w_voms._run!
      expect(strategy_w_voms.user).not_to eq nil
    end

    it "sets expected values for credentials" do
      strategy_w_voms._run!

      expect(strategy_w_voms.user.auth!.type).to eq 'voms'
      expect(strategy_w_voms.user.auth!.credentials!.client_cert_dn).to eq valid_voms['SSL_CLIENT_S_DN']
      expect(strategy_w_voms.user.auth!.credentials!.client_cert).to eq valid_voms['SSL_CLIENT_CERT'] unless valid_voms['SSL_CLIENT_CERT'].blank?
      expect(strategy_w_voms.user.auth!.credentials!.client_cert_voms_attrs).to eq [{"vo"=>"vo.example.org", "role"=>"NULL", "capability"=>"NULL"}]
      expect(strategy_w_voms.user.auth!.credentials!.verification_status).to eq valid_voms['SSL_CLIENT_VERIFY']
    end

    it "reports a success" do
      strategy_w_voms._run!
      expect(strategy_w_voms.result).to be :success
    end

  end

  describe "with invalid SSL_CLIENT_* and GRST_CRED_* headers set" do

    it "halts the strategies when failing" do
      strategy_w_invalid_voms._run!
      expect(strategy_w_invalid_voms).to be_halted
    end

    it "allows you to set a message when failing on VOMS matching" do
      strategy_w_invalid_voms._run!
      expect(strategy_w_invalid_voms.message).to eq "Could not extract VOMS attributes from user's credentials!"
    end

    it "allows you to set a message when failing on DN matching" do
      strategy_w_invalid_voms2._run!
      expect(strategy_w_invalid_voms2.message).to eq "Could not extract user's DN from credentials!"
    end

    it "reports a failure for invalid VOMS attributes" do
      strategy_w_invalid_voms._run!
      expect(strategy_w_invalid_voms.result).to be :failure
    end

    it "reports a failure for invalid cert DN" do
      strategy_w_invalid_voms2._run!
      expect(strategy_w_invalid_voms2.result).to be :failure
    end

  end

end
