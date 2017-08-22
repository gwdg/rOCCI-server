module Configurable
  extend ActiveSupport::Concern

  class_methods do
    # Returns application configuration as a hash.
    #
    # @return [Hash] configuration
    def app_config
      Rails.configuration.rocci_server
    end
  end

  included do
    delegate :app_config, to: :class
  end

  # Returns full server URI.
  #
  # @return [String] public FQDN of the server, including the port number, no trailing slash
  def server_url
    "https://#{app_config.fetch('hostname')}:#{app_config.fetch('port')}"
  end

  # Turns given relative URI to absolute URI by prefixing it with `server_url`.
  #
  # @param relative [String] relative URL, incl. the leading slash
  # @return [String] absolute URL
  def absolute_url(relative)
    "#{server_url}#{relative}"
  end
end
