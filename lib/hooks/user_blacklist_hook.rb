module Hooks
  class UserBlacklistHook

    STATIC_RESPONSE = [403, {"Content-Type" => "text/plain"}, ["Your identity has been banned!"]]

    def initialize(app, options)
      @app = app
      @options = options
      @filtered_strategies = options.filtered_strategies.kind_of?(String) ? options.filtered_strategies.split(' ') : options.filtered_strategies
    end

    def call(env)
      request = ::ActionDispatch::Request.new(env)

      unless @options.user_blacklist.blank? || @filtered_strategies.blank?
        # trigger Warden early to get user information
        request.env['warden'].authenticate!
        user_stuct = request.env['warden'].user || ::Hashie::Mash.new

        # look up blocked users only for specified strategies
        if user_stuct.auth_.type && @filtered_strategies.include?(user_stuct.auth_.type)
          user_blacklist = AuthenticationStrategies::Helpers::YamlHelper.read_yaml(@options.user_blacklist)
          return STATIC_RESPONSE if user_blacklist.include?(user_stuct.identity)
        end
      end

      @app.call(env)
    end
  end
end
