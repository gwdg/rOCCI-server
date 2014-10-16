require 'spec_helper'

describe AuthenticationStrategies::BasicStrategy do
  before(:each) do
    Warden::Strategies.clear!
    AuthenticationStrategies::BasicStrategy.send(:remove_const, :OPTIONS) if AuthenticationStrategies::BasicStrategy.const_defined?(:OPTIONS)
    AuthenticationStrategies::BasicStrategy.const_set(
      :OPTIONS,
      RocciSpecHelpers::YamlHelper.read_yaml("#{File.join(Rails.application.config.rocci_server_etc_dir,'authn_strategies', 'basic', Rails.env + '.yml')}")
    )
    Warden::Strategies.add :basic, AuthenticationStrategies::BasicStrategy
  end

  after(:each) do
    Warden::Strategies.clear!
    AuthenticationStrategies::BasicStrategy.send(:remove_const, :OPTIONS) if AuthenticationStrategies::BasicStrategy.const_defined?(:OPTIONS)
    AuthenticationStrategies::BasicStrategy.const_set(
      :OPTIONS,
      RocciSpecHelpers::YamlHelper.read_yaml("#{File.join(Rails.application.config.rocci_server_etc_dir,'authn_strategies', 'basic', Rails.env + '.yml')}")
    )
    # TODO: read the default strategy from Rails.application.config.rocci_server_etc_dir/ENV.yml
    Warden::Strategies.add :dummy, AuthenticationStrategies::DummyStrategy
  end

  let(:strategy){ Warden::Strategies[:basic].new(Warden::Test::StrategyHelper.env_with_params) }
  let(:valid_basic) { { "HTTP_AUTHORIZATION" => "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==" } }
  let(:invalid_basic) { { "HTTP_AUTHORIZATION" => "Basic GS83fhu123=" } }
  let(:strategy_w_basic){ Warden::Strategies[:basic].new(Warden::Test::StrategyHelper.env_with_params('/', {}, valid_basic)) }
  let(:strategy_w_invalid_basic){ Warden::Strategies[:basic].new(Warden::Test::StrategyHelper.env_with_params('/', {}, invalid_basic)) }

  describe "implements required methods" do

    it "responds to valid?" do
      expect(strategy).to respond_to :valid?
    end

    it "is not valid without authorization header present" do
      expect(strategy.valid?).to be false
    end

    it "is valid with authorization header present" do
      expect(strategy_w_basic.valid?).to be true
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

  describe "with authorization header set" do

    it "sets a user" do
      strategy_w_basic._run!
      expect(strategy_w_basic.user).not_to eq nil
    end

    it "sets expected values for username and password" do
      strategy_w_basic._run!

      expect(strategy_w_basic.user.auth!.type).to eq 'basic'
      expect(strategy_w_basic.user.auth!.credentials!.username).to eq 'Aladdin'
      expect(strategy_w_basic.user.auth!.credentials!.password).to eq 'open sesame'
      expect(strategy_w_basic.user.identity).to eq 'Aladdin'
    end

    it "reports a success" do
      strategy_w_basic._run!
      expect(strategy_w_basic.result).to be :success
    end

  end

  describe "with invalid authorization header set" do

    it "halts the strategies when failing" do
      strategy_w_invalid_basic._run!
      expect(strategy_w_invalid_basic).to be_halted
    end

    it "allows you to set a message when failing" do
      strategy_w_invalid_basic._run!
      expect(strategy_w_invalid_basic.message).to eq "Provided username contains invalid characters!"
    end

    it "reports a failure" do
      strategy_w_invalid_basic._run!
      expect(strategy_w_invalid_basic.result).to be :failure
    end

  end

end
