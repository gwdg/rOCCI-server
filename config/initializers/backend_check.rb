# Check whether a backend is selected in Rails.application.config.rocci_server_etc_dir/ENV.yml
required_backends = %w(compute storage network).freeze
required_backends.each do |required_backend|
  backend = ROCCI_SERVER_CONFIG.common.backend[required_backend.to_sym]

  if backend.blank?
    message = "You have not specified a #{required_backend} backend!"
    Rails.logger.error "[Backend] #{message}"
    fail Errors::BackendClassNotSetError, message
  end

  # hashes or arrays with multiple backends are not supported
  unless backend.kind_of? String
    message = "You have to specify a single valid #{required_backend} backend!"
    Rails.logger.error "[Backend] #{message}"
    fail Errors::BackendClassNotSetError, message
  end

  # check backend's compliance with the current API version
  Rails.logger.debug '[Backend] Checking backend API version'
  b_class = Backend.load_backend_class(backend)

  unless b_class.const_defined?(:API_VERSION)
    message = "#{b_class} does not expose API_VERSION and cannot be loaded"
    Rails.logger.error "[Backend] #{message}"
    fail Errors::BackendApiVersionMissingError, message
  end

  Backend.check_version(Backend::API_VERSION, b_class::API_VERSION)
end
