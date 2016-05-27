module Backends
  module Dummy
    class Base
      API_VERSION = '1.0.0'
      FIXTURES = [:compute, :network, :storage].freeze
      FIXTURES_TPL = [:os_tpl, :resource_tpl].freeze

      # load helpers for JSON -> Collection conversion
      include Backends::Helpers::JsonCollectionHelper

      def initialize(delegated_user, options, server_properties, logger, dalli_cache)
        @delegated_user = Hashie::Mash.new(delegated_user)
        @options = Hashie::Mash.new(options)
        @server_properties = Hashie::Mash.new(server_properties)
        @logger = logger || Rails.logger
        @dalli_cache = dalli_cache
        @other_backends = {}

        path = @options.fixtures_dir || ''
        read_fixtures(path)
      end

      def add_other_backend(backend_type, backend_instance)
        fail 'Type and instance must be provided!' unless backend_type && backend_instance
        @other_backends[backend_type] = backend_instance
      end

      private

      # load helpers for working with OCCI extensions
      include Backends::Helpers::ExtensionsHelper

      def read_fixtures(base_path)
        @logger.debug "[Backends] [Dummy] Reading fixtures from #{base_path.to_s.inspect}"
        (FIXTURES + FIXTURES_TPL).each { |name| send "read_#{name}_fixtures", base_path }
      end

      FIXTURES.each do |fixture|
        class_eval %Q|
def read_#{fixture}_fixtures(path = '')
  #{fixture} = Rails.env.test? ? @#{fixture} : @dalli_cache.get('dummy_#{fixture}')

  unless #{fixture}
    path = path_for_fixture_file(path, :#{fixture})
    @logger.debug "[Backends] [Dummy] Reloading #{fixture} fixtures from '" + path.to_s + "'"
    #{fixture} = File.readable?(path) ? read_from_json(path).resources : Occi::Core::Resources.new
    save_#{fixture}_fixtures(#{fixture})
  end

  #{fixture}
end

def save_#{fixture}_fixtures(#{fixture})
  Rails.env.test? ? @#{fixture} = #{fixture} : @dalli_cache.set('dummy_#{fixture}', #{fixture})
end

def drop_#{fixture}_fixtures(lite = true)
  if lite
    save_#{fixture}_fixtures(Occi::Core::Resources.new)
  else
    Rails.env.test? ? @#{fixture} = nil : @dalli_cache.delete('dummy_#{fixture}')
  end
end
|
      end

      FIXTURES_TPL.each do |fixture_tpl|
        class_eval %Q|
def read_#{fixture_tpl}_fixtures(path = '')
  #{fixture_tpl} = Rails.env.test? ? @#{fixture_tpl} : @dalli_cache.get('dummy_#{fixture_tpl}')

  unless #{fixture_tpl}
    path = path_for_fixture_file(path, :#{fixture_tpl})
    @logger.debug "[Backends] [Dummy] Reloading #{fixture_tpl} fixtures from '" + path.to_s + "'"
    #{fixture_tpl} = File.readable?(path) ? read_from_json(path).mixins : Occi::Core::Mixins.new
    save_#{fixture_tpl}_fixtures(#{fixture_tpl})
  end

  #{fixture_tpl}
end

def save_#{fixture_tpl}_fixtures(#{fixture_tpl})
  Rails.env.test? ? @#{fixture_tpl} = #{fixture_tpl} : @dalli_cache.set('dummy_#{fixture_tpl}', #{fixture_tpl})
end
|
      end

      def path_for_fixture_file(path, fixture_type)
        return path if path && path.to_s.end_with?('.json')
        path = @options.fixtures_dir if path.blank?

        fail Backends::Errors::ResourceRetrievalError, "Unable to read fixtures " \
             "from an unspecified directory!" if path.blank?
        fail Backends::Errors::ResourceRetrievalError, "Unable to read fixtures " \
             "for #{fixture_type.to_s.inspect}!" unless (FIXTURES + FIXTURES_TPL).include? fixture_type

        File.join(path, "#{fixture_type}.json")
      end
    end
  end
end
