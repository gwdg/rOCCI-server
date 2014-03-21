module Backends
  class DummyBackend
    API_VERSION = '0.0.1'
    FIXTURES = [:compute, :network, :storage, :os_tpl, :resource_tpl].freeze

    def initialize(delegated_user, options, server_properties, logger, dalli_cache)
      @delegated_user = Hashie::Mash.new(delegated_user)
      @options = Hashie::Mash.new(options)
      @server_properties = Hashie::Mash.new(server_properties)
      @logger = logger || Rails.logger
      @dalli_cache = dalli_cache

      path = @options.fixtures_dir || ''
      read_fixtures(path)
    end

    def read_fixtures(path)
      FIXTURES.each { |name| send "read_#{name.to_s}_fixtures", "#{File.join(path, name.to_s)}.json" }
    end

    def read_compute_fixtures(path = '')
      unless compute = @dalli_cache.get('dummy_compute')
        compute = File.readable?(path) ? read_from_json(path).resources : Occi::Core::Resources.new
        @dalli_cache.set 'dummy_compute', compute
      end

      compute
    end

    def save_compute_fixtures(compute)
      @dalli_cache.set 'dummy_compute', compute
    end

    def drop_compute_fixtures
      @dalli_cache.delete 'dummy_compute'
    end

    def read_network_fixtures(path = '')
      unless network = @dalli_cache.get('dummy_network')
        network = File.readable?(path) ? read_from_json(path).resources : Occi::Core::Resources.new
        @dalli_cache.set 'dummy_network', network
      end

      network
    end

    def save_network_fixtures(network)
      @dalli_cache.set 'dummy_network', network
    end

    def drop_network_fixtures
      @dalli_cache.delete 'dummy_network'
    end

    def read_storage_fixtures(path = '')
      unless storage = @dalli_cache.get('dummy_storage')
        storage = File.readable?(path) ? read_from_json(path).resources : Occi::Core::Resources.new
        @dalli_cache.set 'dummy_storage', storage
      end

      storage
    end

    def save_storage_fixtures(storage)
      @dalli_cache.set 'dummy_storage', storage
    end

    def drop_storage_fixtures
      @dalli_cache.delete 'dummy_storage'
    end

    def read_os_tpl_fixtures(path = '')
      unless os_tpl = @dalli_cache.get('dummy_os_tpl')
        os_tpl = File.readable?(path) ? read_from_json(path).mixins : Occi::Core::Mixins.new
        @dalli_cache.set 'dummy_os_tpl', os_tpl
      end

      os_tpl
    end

    def read_resource_tpl_fixtures(path = '')
      unless resource_tpl = @dalli_cache.get('dummy_resource_tpl')
        resource_tpl = File.readable?(path) ? read_from_json(path).mixins : Occi::Core::Mixins.new
        @dalli_cache.set 'dummy_resource_tpl', resource_tpl
      end

      resource_tpl
    end

    # load helpers for JSON -> Collection conversion
    include Backends::Helpers::JsonCollectionHelper

    # hide internal stuff
    private :read_fixtures
    private :read_storage_fixtures
    private :read_network_fixtures
    private :read_compute_fixtures
    private :read_os_tpl_fixtures
    private :read_resource_tpl_fixtures
    private :read_from_json

    # load API implementation
    include Backends::Dummy::Compute
    include Backends::Dummy::Network
    include Backends::Dummy::Storage
    include Backends::Dummy::OsTpl
    include Backends::Dummy::ResourceTpl
  end
end
