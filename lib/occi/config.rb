require "yaml"
require "singleton"

module OCCI
  class Config
    include Singleton

    # Example
    # Config.instance.amqp[:connection_setting]

    def initialize
      @_settings = YAML::load_file(File.dirname(__FILE__) + "/../../etc/configuration.yml")[ENV['RACK_ENV'] || 'default']
      @_settings = deep_symbolize(@_settings)
    end

    def method_missing(name, *args, &block)
      @_settings[name.to_sym] || fail(NoMethodError, "unknown configuration root #{name}", caller)
    end

    private
    ####################################################################################################################

    def deep_symbolize(hash, &block)
      hash.inject({}) do |result, (key, value)|
        # Recursively deep-symbolize subhashes
        value = _recurse_(value, &block)

        # Pre-process the key with a block if it was given
        key = yield key if block_given?
        # Symbolize the key string if it responds to to_sym
        sym_key = key.to_sym rescue key

        # write it back into the result and return the updated hash
        result[sym_key] = value
        result
      end
    end

    # handling recursion - any Enumerable elements (except String)
    def _recurse_(value, &block)
      if value.is_a?(Enumerable) && !value.is_a?(String)
        # support for a use case without extended core Hash
        value = deep_symbolize(value, &block)
      end
      value
    end

  end
end