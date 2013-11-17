# Check whether a backend is selected in Rails.root/etc/common.yml
backend = ROCCI_SERVER_CONFIG.common.backend

if backend.blank?
  message = "You have not specified a backend!"
  Rails.logger.error "[Backend] #{message}"
  raise Errors::BackendClassNotSetError, message
end

# hashes or arrays with multiple backends are not supported
unless backend.kind_of? String
  message = "You have to specify a single backend!"
  Rails.logger.error "[Backend] #{message}"
  raise Errors::BackendClassNotSetError, message
end

# check backend's compliance with the current API version
Rails.logger.info "[Backend] Checking backend API version"
b_class = Backend.load_backend_class(ROCCI_SERVER_CONFIG.common.backend)
Backend.check_version(b_class)