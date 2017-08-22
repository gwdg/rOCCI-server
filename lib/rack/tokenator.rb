require 'rack'
require 'openssl'
require 'base64'

module Rack
  class Tokenator
    INTERNAL_TOKEN_SEPARATOR = ':'.freeze
    TOKEN_HEADER_KEY = 'HTTP_X_AUTH_TOKEN'.freeze
    TOKENATOR_ENV_NAMESPACE = 'rocci_server.request.tokenator'.freeze

    REDIRECT_HEADER_KEY = ApplicationController.redirect_header_key.freeze
    REDIRECT_HEADER_URI = ApplicationController.redirect_header_uri.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      initial_env! env

      processed_token = env[TOKEN_HEADER_KEY].blank? ? nil : process(env[TOKEN_HEADER_KEY])
      if processed_token
        logger.debug "Identified token from #{env['REMOTE_ADDR']} as #{processed_token.fetch(:user).inspect}"
        success_env! env, processed_token
      else
        logger.debug "No or invalid token from #{env['REMOTE_ADDR']}"
        return [401, response_headers, ['Not Authorized']]
      end

      @app.call(env)
    end

    private

    def logger
      Rails.logger
    end

    def app_config
      Rails.configuration.rocci_server['encryption']
    end

    def default_headers
      { 'Content-Type' => 'text/plain' }
    end

    def response_headers
      default_headers.merge(REDIRECT_HEADER_KEY => REDIRECT_HEADER_URI)
    end

    def initial_env!(env)
      env["#{TOKENATOR_ENV_NAMESPACE}.authorized"] = false
    end

    def success_env!(env, processed_token)
      env["#{TOKENATOR_ENV_NAMESPACE}.user"] = processed_token.fetch(:user)
      env["#{TOKENATOR_ENV_NAMESPACE}.token"] = processed_token.fetch(:token)
      env["#{TOKENATOR_ENV_NAMESPACE}.authorized"] = true
    end

    def process(token)
      read_decrypted(
        decrypt_unwrapped(
          unwrap_raw(token)
        )
      )
    end

    def unwrap_raw(token)
      Base64.strict_decode64(token)
    rescue => ex
      logger.error "Failed to unwrap token: #{ex}"
      nil
    end

    def decrypt_unwrapped(token)
      return unless token
      return token if app_config['token_cipher'].blank?

      logger.debug "Decrypting token as #{app_config['token_cipher'].inspect}"
      decipher = decrypt_cipher(app_config['token_cipher'], app_config['token_key'], app_config['token_iv'])
      decipher.update(token) + decipher.final
    rescue => ex
      logger.error "Failed to decrypt token: #{ex}"
      nil
    end

    def read_decrypted(token)
      return unless token

      parts = token.split(INTERNAL_TOKEN_SEPARATOR)
      if parts.count != 2 || parts[0].blank? || parts[1].blank?
        raise "Token is malformed when split using '#{INTERNAL_TOKEN_SEPARATOR}'"
      end

      { user: parts[0], token: parts[1] }
    rescue => ex
      logger.error "Failed to read token: #{ex}"
      nil
    end

    def decrypt_cipher(token_cipher, token_key, token_iv)
      decipher = OpenSSL::Cipher.new(token_cipher)
      decipher.decrypt
      decipher.key = token_key
      decipher.iv = token_iv

      decipher
    end
  end
end
