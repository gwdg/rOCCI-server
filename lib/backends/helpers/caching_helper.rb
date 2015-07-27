module Backends
  module Helpers
    # Helps with cache handling with Dalli.
    module CachingHelper
      # Saves `data` under `key` in the given caching instance.
      #
      # @param dalli_instance [::Dalli::Client] caching instance
      # @param key [String] key value
      # @param data [Object] data to store
      # @return [Boolean] success or failure
      def self.save(dalli_instance, key, data)
        return if dalli_instance.blank? || key.blank?

        begin
          dalli_instance.set(key, data)
          true
        rescue
          # ignore
          false
        end
      end

      # Loads `data` under `key` from the given caching instance.
      #
      # @param dalli_instance [::Dalli::Client] caching instance
      # @param key [String] key value
      # @return [Object,NilClass] data or nothing
      def self.load(dalli_instance, key)
        return if dalli_instance.blank? || key.blank?

        begin
          dalli_instance.get(key)
        rescue
          nil
        end
      end

      # Drops `data` under `key` in the given caching instance.
      #
      # @param dalli_instance [::Dalli::Client] caching instance
      # @param key [String] key value
      # @return [Boolean] success or failure
      def self.drop(dalli_instance, key)
        return if dalli_instance.blank? || key.blank?

        begin
          dalli_instance.delete(key)
          true
        rescue
          # ignore
          false
        end
      end
    end
  end
end
