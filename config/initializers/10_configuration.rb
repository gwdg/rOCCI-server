# Initialize a Mash
ROCCI_SERVER_CONFIG = Hashie::Mash.new

def get_yaml_config(path, env = Rails.env)
  begin
    Rails.logger.info "[Configuration] Loading configuration from #{path} for ENV #{env}."
    YAML.load(ERB.new(File.read(path)).result)[env]
  rescue Exception => err
    message = "Failed to parse a configuration file! [#{path}]: #{err.message}"
    Rails.logger.error "[Configuration] #{message}"
    raise Errors::ConfigurationParsingError, message
  end
end
private :get_yaml_config

# Load general configuration from 'etc/common.yml'
ROCCI_SERVER_CONFIG.common = get_yaml_config(Rails.root.join('etc', 'common.yml')).deep_freeze

# Load hook configuration from 'etc/hooks.yml'
ROCCI_SERVER_CONFIG.hooks = get_yaml_config(Rails.root.join('etc', 'hooks.yml')).deep_freeze

# Load backend configuration from 'etc/backends.yml'
ROCCI_SERVER_CONFIG.backends = get_yaml_config(Rails.root.join('etc', 'backends.yml')).deep_freeze

# Load backend configuration from 'etc/authn_strategies.yml'
ROCCI_SERVER_CONFIG.authn_strategies = get_yaml_config(Rails.root.join('etc', 'authn_strategies.yml')).deep_freeze