# Initialize ::Occi::Log and change log_level if applicable
Rails.application.config.log_level = ::Occi::Log.const_get(ROCCI_SERVER_CONFIG.common.log_level.upcase.to_sym) if ROCCI_SERVER_CONFIG.common.log_level
_logger = ::Occi::Log.new(Rails.application.config.logger)
