require 'openssl'
require 'base64'

class Tokenator
  INTERNAL_TOKEN_SEPARATOR = ':'.freeze

  attr_reader :user, :token, :options

  def initialize(args = {})
    @_raw_token = args.fetch(:token)
    @options = args.fetch(:options)
  end

  def logger
    Rails.logger
  end

  def process!
    unwrap_raw_token! && \
      decrypt_unwrapped_token! && \
      read_decrypted_token!
  end

  private

  def unwrap_raw_token!
    @_unwrapped_token = Base64.strict_decode64(@_raw_token)
  rescue => ex
    logger.error "Failed to unwrap token: #{ex}"
    nil
  end

  def decrypt_unwrapped_token!
    raise 'No unwrapped token is present' if @_unwrapped_token.blank?
    if options['token_cipher'].blank?
      logger.debug 'Decryption cipher is not set, skipping token decrypt'
      return @_decrypted_token = @_unwrapped_token
    end

    # TODO: is this raising errors?
    @_decrypted_token = decipher.update(@_unwrapped_token) + decipher.final
  rescue => ex
    logger.error "Failed to decrypt token: #{ex}"
    nil
  end

  def read_decrypted_token!
    raise 'No decrypted token is present' if @_decrypted_token.blank?
    parts = @_decrypted_token.split(INTERNAL_TOKEN_SEPARATOR)

    if parts.count != 2 || parts.first.blank? || parts.last.blank?
      raise "Token is malformed when split using '#{INTERNAL_TOKEN_SEPARATOR}'"
    end

    @user, @token = parts
  rescue => ex
    logger.error "Failed to read token: #{ex}"
    nil
  end

  def decipher
    return @_decipher if @_decipher

    @_decipher = OpenSSL::Cipher.new(options['token_cipher'])
    @_decipher.decrypt
    @_decipher.key = options['token_key']
    @_decipher.iv = options['token_iv']

    @_decipher
  end
end
