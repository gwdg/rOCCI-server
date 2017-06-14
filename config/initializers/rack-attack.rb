# Rack attack protection
class Rack::Attack
  throttle('req/ip', :limit => 300, :period => 1.minutes) { |req| req.ip }

  blocklist('basic auth crackers') do |req|
    Allow2Ban.filter(req.ip, :maxretry => 10, :findtime => 1.minute, :bantime => 1.hour) do
      req.env['HTTP_X_Auth_Token'].blank?
    end
  end
end

Rails.application.config.middleware.use Rack::Attack if Rails.env.production?
