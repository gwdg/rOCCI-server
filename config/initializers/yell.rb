# Initialize loggers for rOCCI-core
rocci_logger = ::Yell.new Rails.root.join('log', "rOCCI-core.#{Rails.env}.log"), name: Object
rocci_logger.level = Rails.application.config.rocci_server['log_level'].to_sym
