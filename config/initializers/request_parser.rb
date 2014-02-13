# Insert RequestParsers::OcciParser as Rack::Middleware
Rails.configuration.middleware.use RequestParsers::OcciParser do |parser|
  # stuff
end
