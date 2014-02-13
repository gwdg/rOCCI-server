# Insert hooks from 'Rails.root/lib/hooks' as Rack::Middleware

# Checks whether required classes are configured alongside
# the given hook. In case of missing dependencies raises
# an exception.
#
# @param hook_class [Class] class of the hook to process
# @param hook_config [Hashie::Mash] configuration of the hook specified in `hook_class`
def check_hook_deps(hook_class, hook_config = Hashie::Mash.new)
  Rails.logger.info "[Hooks] Checking deps for #{hook_class.to_s}"
  loaded_backend = ROCCI_SERVER_CONFIG.common.backend
  required_backend = hook_config.required_backend

  if required_backend
    Rails.logger.debug "[Hooks] Validating deps=#{required_backend.inspect} for #{hook_class.to_s}"

    if required_backend.kind_of?(Array)
      found = required_backend.include?(loaded_backend)
    else
      found = (required_backend == loaded_backend)
    end

    unless found
      message = "#{hook_class.to_s} requires #{required_backend.inspect} as a backend but #{loaded_backend.inspect} is loaded!"
      Rails.logger.error "[Hooks] #{message}"
      fail Errors::HookDepsError, message
    end
  end
end
private :check_hook_deps

ROCCI_SERVER_CONFIG.common.hooks.each do |hook_name|
  hook_class = ::Hooks.const_get("#{hook_name.camelize}Hook")
  Rails.logger.info "[Hooks] Registering #{hook_class.to_s}"

  options = ROCCI_SERVER_CONFIG.hooks.send(hook_name.to_sym) || Hashie::Mash.new
  Rails.logger.debug "[Hooks] Inserting #{hook_class.to_s} with options=#{options.inspect}"

  check_hook_deps(hook_class, options)
  Rails.configuration.middleware.insert_after RequestParsers::OcciParser, hook_class, options
end unless ROCCI_SERVER_CONFIG.common.hooks.blank?
