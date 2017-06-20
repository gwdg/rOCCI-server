require 'backends/dummy/base'

module Backends
  module Dummy
    class Compute < Base
      def identifiers(filter); end
      def list(filter); end
      def instance(identifier); end
      def create(instance); end
      def partial_update(identifier, fragments); end
      def update(identifier, new_instance); end
      def trigger(identifier, action_instance); end
      def trigger_all(filter, action_instance); end
      def delete(identifier); end
      def delete_all(filter); end
    end
  end
end
