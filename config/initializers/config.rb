# Initialize a Mash
ROCCI_SERVER_CONFIG = Hashie::Mash.new

def get_yaml_config(path, env = Rails.env)
  begin
    Rails.logger.info "Loading configuration from #{path} for ENV #{env}."
    YAML.load_file(path)[env]
  rescue Error => err
    message = "Failed to parse a configuration file! [#{path}]"
    Rails.logger.error message
    raise Errors::ConfigurationParsingError, message
  end
end
private :get_yaml_config

# Load general configuration from 'config/config.yml'
ROCCI_SERVER_CONFIG.common = get_yaml_config(Rails.root.join('config', 'config.yml'))

# Load hook configuration from 'config/hooks.yml'
ROCCI_SERVER_CONFIG.hooks = get_yaml_config(Rails.root.join('config', 'hooks.yml'))

# Load backend configuration from 'config/backends.yml'
ROCCI_SERVER_CONFIG.backends = get_yaml_config(Rails.root.join('config', 'backends.yml'))