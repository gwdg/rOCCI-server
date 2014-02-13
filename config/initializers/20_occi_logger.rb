# Initialize ::Occi::Log
logger = ::Occi::Log.new(Rails.logger)
logger.level = ::Occi::Log.const_get(ROCCI_SERVER_CONFIG.common.log_level.upcase.to_sym) if ROCCI_SERVER_CONFIG.common.log_level
