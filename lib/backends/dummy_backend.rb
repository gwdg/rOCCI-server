module Backends
  class DummyBackend
    API_VERSION = '0.0.1'
    FIXTURES = [:compute, :network, :storage].freeze
    FIXTURES_TPL = [:os_tpl, :resource_tpl].freeze

    def initialize(delegated_user, options, server_properties, logger, dalli_cache)
      @delegated_user = Hashie::Mash.new(delegated_user)
      @options = Hashie::Mash.new(options)
      @server_properties = Hashie::Mash.new(server_properties)
      @logger = logger || Rails.logger
      @dalli_cache = dalli_cache

      path = @options.fixtures_dir || ''
      read_fixtures(path)
    end

    def read_fixtures(base_path)
      @logger.debug "[Backends] [DummyBackend] Reading fixtures from #{base_path.to_s.inspect}"
      (FIXTURES + FIXTURES_TPL).each { |name| send "read_#{name.to_s}_fixtures", base_path }
    end

    FIXTURES.each do |fixture|
      class_eval %Q|
def read_#{fixture}_fixtures(path = '')
  #{fixture} = Rails.env.test? ? @#{fixture} : @dalli_cache.get('dummy_#{fixture}')

  unless #{fixture}
    path = path_for_fixture_file(path, :#{fixture})
    @logger.debug "[Backends] [DummyBackend] Reloading #{fixture} fixtures from '" + path.to_s + "'"
    #{fixture} = File.readable?(path) ? read_from_json(path).resources : Occi::Core::Resources.new
    save_#{fixture}_fixtures(#{fixture})
  end

  #{fixture}
end
private :read_#{fixture}_fixtures

def save_#{fixture}_fixtures(#{fixture})
  Rails.env.test? ? @#{fixture} = #{fixture} : @dalli_cache.set('dummy_#{fixture}', #{fixture})
end
private :save_#{fixture}_fixtures

def drop_#{fixture}_fixtures(lite = true)
  if lite
    save_#{fixture}_fixtures(Occi::Core::Resources.new)
  else
    Rails.env.test? ? @#{fixture} = nil : @dalli_cache.delete('dummy_#{fixture}')
  end
end
private :drop_#{fixture}_fixtures
|
    end

    FIXTURES_TPL.each do |fixture_tpl|
      class_eval %Q|
def read_#{fixture_tpl}_fixtures(path = '')
  #{fixture_tpl} = Rails.env.test? ? @#{fixture_tpl} : @dalli_cache.get('dummy_#{fixture_tpl}')

  unless #{fixture_tpl}
    path = path_for_fixture_file(path, :#{fixture_tpl})
    @logger.debug "[Backends] [DummyBackend] Reloading #{fixture_tpl} fixtures from '" + path.to_s + "'"
    #{fixture_tpl} = File.readable?(path) ? read_from_json(path).mixins : Occi::Core::Mixins.new
    save_#{fixture_tpl}_fixtures(#{fixture_tpl})
  end

  #{fixture_tpl}
end
private :read_#{fixture_tpl}_fixtures

def save_#{fixture_tpl}_fixtures(#{fixture_tpl})
  Rails.env.test? ? @#{fixture_tpl} = #{fixture_tpl} : @dalli_cache.set('dummy_#{fixture_tpl}', #{fixture_tpl})
end
private :save_#{fixture_tpl}_fixtures
|
    end

    def path_for_fixture_file(path, fixture_type)
      return path if path && path.to_s.end_with?('.json')
      path = @options.fixtures_dir if path.blank?

      fail Backends::Errors::ResourceRetrievalError, "Unable to read fixtures " \
           "from an unspecified directory!" if path.blank?
      fail Backends::Errors::ResourceRetrievalError, "Unable to read fixtures " \
           "for #{fixture_type.to_s.inspect}!" unless (FIXTURES + FIXTURES_TPL).include? fixture_type

      File.join(path, "#{fixture_type.to_s}.json")
    end

    # load helpers for JSON -> Collection conversion
    include Backends::Helpers::JsonCollectionHelper

    # hide internal stuff
    private :read_fixtures
    private :read_from_json
    private :path_for_fixture_file

    # load API implementation
    include Backends::Dummy::Compute
    include Backends::Dummy::Network
    include Backends::Dummy::Storage
    include Backends::Dummy::OsTpl
    include Backends::Dummy::ResourceTpl
  end
end
