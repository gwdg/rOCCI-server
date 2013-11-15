module Backends
  class Dummy

    API_VERSION = "0.0.1"
    FIXTURES = [:compute, :network, :storage, :os_tpl, :resource_tpl].freeze

    def initialize(delegated_user, options, server_properties, logger)
      @delegated_user = Hashie::Mash.new(delegated_user)
      @options = Hashie::Mash.new(options)
      @server_properties = Hashie::Mash.new(server_properties)
      @logger = logger || Rails.logger

      path = @options.fixtures_dir || ""
      read_fixtures(path)
    end

    def read_fixtures(path)
      FIXTURES.each { |name| send "read_#{name.to_s}_fixtures", "#{File.join(path, name.to_s)}.json" }
    end

    def read_compute_fixtures(path)
      @compute = File.readable?(path) ? read_from_json(path).resources : Occi::Core::Resources.new
    end

    def read_network_fixtures(path)
      @network = File.readable?(path) ? read_from_json(path).resources : Occi::Core::Resources.new
    end

    def read_storage_fixtures(path)
      @storage = File.readable?(path) ? read_from_json(path).resources : Occi::Core::Resources.new
    end

    def read_os_tpl_fixtures(path)
      @os_tpl = File.readable?(path) ? read_from_json(path).mixins : Occi::Core::Mixins.new
    end

    def read_resource_tpl_fixtures(path)
      @resource_tpl = File.readable?(path) ? read_from_json(path).mixins : Occi::Core::Mixins.new
    end

    def read_from_json(path)
      collection = Occi::Collection.new
      collection.model = nil

      # Load all JSON files in the given directory, these contain
      # JSON rendering of OCCI kind/mixin/action definitions
      Rails.logger.debug "[#{self}] Getting fixtures from #{path}"
      parsed = JSON.parse(File.read(path))
      collection.merge! Occi::Collection.new(parsed)

      collection
    end

    # hide internal stuff
    private :read_fixtures
    private :read_storage_fixtures
    private :read_network_fixtures
    private :read_compute_fixtures
    private :read_os_tpl_fixtures
    private :read_resource_tpl_fixtures
    private :read_from_json

    # load API implementation
    include Backends::Compute::Dummy
    include Backends::Network::Dummy
    include Backends::Storage::Dummy
    include Backends::OsTpl::Dummy
    include Backends::ResourceTpl::Dummy

  end
end