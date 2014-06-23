module Backends
  module Helpers
    module CachingHelper

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

      def self.load(dalli_instance, key)
        return if dalli_instance.blank? || key.blank?

        begin
          dalli_instance.get(key)
        rescue
          nil
        end
      end

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
