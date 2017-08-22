require 'erb'

module Backends
  module Helpers
    module ErbRenderer
      extend ActiveSupport::Concern

      # Ruby 2.3 compatibility, with `$SAFE` changes
      RENDER_SAFE = RUBY_VERSION >= '2.3' ? 1 : 3

      included do
        delegate :render_safe, to: :class
      end

      class_methods do
        # Returns an acceptable value for the $SAFE env variable
        # that should be enforced when evaluating templates.
        #
        # @return [Integer] SAFE level
        def render_safe
          RENDER_SAFE
        end
      end

      # Safely renders given `template` to a string with ERB.
      #
      # @param template_path [String] path to ERB template to render
      # @param data [Hash] data to use when rendering
      # @option data [Occi::Core::Entity] :instance instance to render
      # @option data [Hash] :identity additional information about the active user
      # @return [String] rendered template
      def erb_render(template_path, data)
        template = File.read(template_path).untaint
        ERB.new(template, render_safe).result(binding)
      end

      # :nodoc:
      def template_directory
        options.fetch(:template_dir) || default_template_dir
      end

      # :nodoc:
      def default_template_dir
        File.join(whereami, 'templates')
      end
    end
  end
end
