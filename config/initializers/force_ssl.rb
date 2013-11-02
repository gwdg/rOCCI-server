# Force SSL according to settings in 'etc/common.yml'
Rails.application.config.force_ssl = ROCCI_SERVER_CONFIG.common.force_ssl