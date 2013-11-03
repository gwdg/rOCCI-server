# Enable the backend selected in Rails.root/etc/common.yml
backend = ROCCI_SERVER_CONFIG.common.backend

unless backend && !backend.blank?
  message = "You have not specified a backend!"
  Rails.logger.error "[Backend] #{message}"
  raise ArgumentError, message
end

backend = "#{backend.classify}"
Rails.logger.info "[Backend] Registering Backends::#{backend}."

begin
  Backend.backend_class = Backends.const_get("#{backend}")
rescue NameError => err
  message = "There is no such backend available! [Backends::#{backend}]"
  Rails.logger.error "[Backend] #{message}"
  raise ArgumentError, message
end

# TODO: check backend's compliance with the current API version