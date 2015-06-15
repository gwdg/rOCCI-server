# Force SSL according to settings in Rails.application.config.rocci_server_etc_dir/ENV.yml
Rails.application.config.force_ssl = (ROCCI_SERVER_CONFIG.common.force_ssl.to_s == 'true')

# Disable mandatory peer verification if SSL_CERT_* vars are not available
if ENV['SSL_CERT_FILE'].blank? && ENV['SSL_CERT_DIR'].blank?
  silence_warnings { OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE }
end
