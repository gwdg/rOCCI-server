# Perform token transformation and early user authorization
require 'rack_tokenator'
Rails.application.config.middleware.use Rack::Tokenator
