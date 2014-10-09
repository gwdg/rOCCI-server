# Initialize a Mash
ROCCI_SERVER_CONFIG = Hashie::Mash.new

def get_yaml_config(path, env = Rails.env)
  begin
    Rails.logger.info "[Configuration] Loading configuration from #{path} for ENV #{env}."
    fail 'Does not exist!' unless Dir.exists?(path)

    path = path.join("#{env}.yml")
    YAML.load(ERB.new(File.read(path)).result) || {}
  rescue Exception => err
    message = "Failed to parse a configuration file! [#{path}]: #{err.message}"
    Rails.logger.error "[Configuration] #{message}"
    raise Errors::ConfigurationParsingError, message
  end
end
private :get_yaml_config

# Load general configuration from 'etc/*.yml'
ROCCI_SERVER_CONFIG.common = get_yaml_config(Rails.application.config.rocci_server_etc_dir)

# Load hook configuration from 'etc/hooks/**/*.yml'
unless ROCCI_SERVER_CONFIG.common.hooks.respond_to?(:each)
  if ROCCI_SERVER_CONFIG.common.hooks
    ROCCI_SERVER_CONFIG.common.hooks = ROCCI_SERVER_CONFIG.common.hooks.split
  else
    ROCCI_SERVER_CONFIG.common.hooks = []
  end
end

ROCCI_SERVER_CONFIG.common.hooks.each do |hook|
  ROCCI_SERVER_CONFIG.hooks![hook] = get_yaml_config(Rails.application.config.rocci_server_etc_dir.join('hooks', hook))
end

# Load backend configuration from 'etc/backends/**/*.yml'
ROCCI_SERVER_CONFIG.backends![ROCCI_SERVER_CONFIG.common.backend] = get_yaml_config(Rails.application.config.rocci_server_etc_dir.join('backends', ROCCI_SERVER_CONFIG.common.backend))

# Load backend configuration from 'etc/authn_strategies/**/*.yml'
unless ROCCI_SERVER_CONFIG.common.authn_strategies.respond_to?(:each)
  if ROCCI_SERVER_CONFIG.common.authn_strategies
    ROCCI_SERVER_CONFIG.common.authn_strategies = ROCCI_SERVER_CONFIG.common.authn_strategies.split
  else
    ROCCI_SERVER_CONFIG.common.authn_strategies = []
  end
end

ROCCI_SERVER_CONFIG.common.authn_strategies.each do |authn_strategy|
  ROCCI_SERVER_CONFIG.authn_strategies![authn_strategy] = get_yaml_config(Rails.application.config.rocci_server_etc_dir.join('authn_strategies', authn_strategy))
end

# Load and normalize memcache endpoints
unless ROCCI_SERVER_CONFIG.common.memcaches.respond_to?(:each)
  if ROCCI_SERVER_CONFIG.common.memcaches
    ROCCI_SERVER_CONFIG.common.memcaches = ROCCI_SERVER_CONFIG.common.memcaches.split
  else
    ROCCI_SERVER_CONFIG.common.memcaches = []
  end
end

# Freeze the config
ROCCI_SERVER_CONFIG.deep_freeze

# Log server version
Rails.logger.info "[Configuration] Starting rOCCI-server/#{ROCCIServer::VERSION} with rOCCI-core/#{ROCCIServer::ROCCI_VERSION} on Ruby/#{RUBY_VERSION}"
