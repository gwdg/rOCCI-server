# Perform token transformation and early user authorization
Rails.application.config.middleware.use Rack::Tokenator
