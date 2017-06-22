# Rack attack protection
module Rack
  class Attack
    throttle('req/ip', limit: 300, period: 1.minute, &:ip)

    blocklist('auth-less annoyances') do |req|
      Allow2Ban.filter(req.ip, maxretry: 10, findtime: 1.minute, bantime: 1.hour) do
        req.env['HTTP_X_AUTH_TOKEN'].blank?
      end
    end
  end
end

Rails.application.config.middleware.use Rack::Attack if Rails.env.production?
