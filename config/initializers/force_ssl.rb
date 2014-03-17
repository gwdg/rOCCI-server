# Force SSL according to settings in Rails.application.config.rocci_server_etc_dir/ENV.yml
Rails.application.config.force_ssl = (ROCCI_SERVER_CONFIG.common.force_ssl.to_s == 'true')
