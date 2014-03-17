# Check whether a backend is selected in Rails.application.config.rocci_server_etc_dir/ENV.yml
backend = ROCCI_SERVER_CONFIG.common.backend

if backend.blank?
  message = 'You have not specified a backend!'
  Rails.logger.error "[Backend] #{message}"
  fail Errors::BackendClassNotSetError, message
end

# hashes or arrays with multiple backends are not supported
unless backend.kind_of? String
  message = 'You have to specify a single backend!'
  Rails.logger.error "[Backend] #{message}"
  fail Errors::BackendClassNotSetError, message
end

# check backend's compliance with the current API version
Rails.logger.info '[Backend] Checking backend API version'
b_class = Backend.load_backend_class(ROCCI_SERVER_CONFIG.common.backend)

unless b_class.const_defined?(:API_VERSION)
  message = "#{b_class} does not expose API_VERSION and cannot be loaded"
  Rails.logger.error "[Backend] #{message}"
  fail Errors::BackendApiVersionMissingError, message
end

Backend.check_version(Backend::API_VERSION, b_class::API_VERSION)
