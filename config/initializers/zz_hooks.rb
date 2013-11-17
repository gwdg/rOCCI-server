# Insert hooks from 'Rails.root/lib/hooks' as Rack::Middleware
ROCCI_SERVER_CONFIG.common.hooks.each do |hook_name|
  hook_class = ::Hooks.const_get(hook_name.camelize)
  Rails.logger.info "[Hooks] Registering #{hook_class.to_s}"

  options = ROCCI_SERVER_CONFIG.hooks.send(hook_name.to_sym) || Hashie::Mash.new
  Rails.logger.debug "[Hooks] Inserting #{hook_class.to_s} with options=#{options.inspect}"
  Rails.configuration.middleware.insert_after RequestParsers::OcciParser, hook_class, options
end unless ROCCI_SERVER_CONFIG.common.hooks.blank?