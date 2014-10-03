module Hooks
  class UserBlacklistHook

    STATIC_RESPONSE = [403, {"Content-Type" => "text/plain"}, ["Your identity has been banned!"]]

    def initialize(app, options)
      @app = app
      @options = options
      @filtered_strategies = options.filtered_strategies.kind_of?(String) ? options.filtered_strategies.split(' ') : options.filtered_strategies

      Rails.logger.debug "[Hooks] [UserBlacklistHook] Enabling blacklisting for " \
                         "#{@filtered_strategies.inspect} with #{@options.user_blacklist.inspect}"
    end

    def call(env)
      request = ::ActionDispatch::Request.new(env)

      unless @options.user_blacklist.blank? || @filtered_strategies.blank?
        # trigger Warden early to get user information
        request.env['warden'].authenticate!
        user_stuct = request.env['warden'].user || ::Hashie::Mash.new

        # look up blocked users only for specified strategies
        Rails.logger.debug "[Hooks] [UserBlacklistHook] Looking up #{user_stuct.inspect} in the blacklist"
        if user_stuct.auth_.type && @filtered_strategies.include?(user_stuct.auth_.type)
          user_blacklist = ::AuthenticationStrategies::Helpers::YamlHelper.read_yaml(@options.user_blacklist)

          if user_blacklist && user_blacklist.include?(user_stuct.identity)
            Rails.logger.warn "[Hooks] [UserBlacklistHook] Blocked a request from #{user_stuct.identity.inspect}"
            return STATIC_RESPONSE
          end
        end
      end

      @app.call(env)
    end
  end
end
