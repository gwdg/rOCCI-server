# Insert Rack::Cors as Rack::Middleware
Rails.configuration.middleware.insert_before 0,
                                             "Rack::Cors",
                                             :debug => (ROCCI_SERVER_CONFIG.common.log_level == 'debug'),
                                             :logger => Rails.logger do
  Rails.logger.info "[CORS] Enabling CORS support for origins #{ROCCI_SERVER_CONFIG.common.cors_support.origins.inspect}"

  allowed_origins = if ROCCI_SERVER_CONFIG.common.cors_support.origins.kind_of?(Array)
    ROCCI_SERVER_CONFIG.common.cors_support.origins
  else
    ROCCI_SERVER_CONFIG.common.cors_support.origins.split(' ')
  end

  allow do
    origins allowed_origins

    resource '*',
             :headers => :any,
             :methods => [:get, :post, :delete, :put, :options],
             :max_age => 0
  end
end if ROCCI_SERVER_CONFIG.common.cors_support.enable
