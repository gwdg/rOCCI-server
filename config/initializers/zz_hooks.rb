# Insert hooks from 'Rails.root/lib/hooks' as Rack::Middleware
ROCCI_SERVER_CONFIG.common.hooks.each do |hook_name|
  hook_class = ::Hooks.const_get(hook_name.camelize)
  Rails.logger.info "[Hooks] Registering hook #{hook_class.to_s}"

  Rails.configuration.middleware.insert_after RequestParsers::OcciParser, hook_class do |hook|
    # stuff
  end
end unless ROCCI_SERVER_CONFIG.common.hooks.blank?