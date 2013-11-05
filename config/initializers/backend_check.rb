# Check whether a backend is selected in Rails.root/etc/common.yml
backend = ROCCI_SERVER_CONFIG.common.backend

unless backend && !backend.blank?
  message = "You have not specified a backend!"
  Rails.logger.error "[Backend] #{message}"
  raise ArgumentError, message
end

# check backend's compliance with the current API version
Backend.check_version(ROCCI_SERVER_CONFIG.common.backend)