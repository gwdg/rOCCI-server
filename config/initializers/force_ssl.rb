# Force SSL according to settings in 'etc/*.yml'
Rails.application.config.force_ssl = (ROCCI_SERVER_CONFIG.common.force_ssl.to_s == 'true')
