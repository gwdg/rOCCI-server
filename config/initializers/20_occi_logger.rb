# Initialize ::Occi::Log
logger = ::Occi::Log.new(Rails.logger)

# Change logging level if applicable
unless ROCCI_SERVER_CONFIG.common.log_level.blank?
  logger.level = ::Occi::Log.const_get(ROCCI_SERVER_CONFIG.common.log_level.upcase.to_sym)
  Rails.application.config.log_level = Rails.logger.class.const_get(ROCCI_SERVER_CONFIG.common.log_level.upcase.to_sym)
end
