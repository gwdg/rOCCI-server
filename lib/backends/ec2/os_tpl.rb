module Backends
  module Ec2
    module OsTpl
      # Gets backend-specific `os_tpl` mixins which should be merged
      # into Occi::Model of the server.
      #
      # @example
      #    mixins = os_tpl_list #=> #<Occi::Core::Mixins>
      #    mixins.first #=> #<Occi::Core::Mixin>
      #
      # @return [Occi::Core::Mixins] a collection of mixins
      def os_tpl_list
        os_tpl = Occi::Core::Mixins.new
        filters = []
        filters << { name: 'image-type', values: ['machine'] }

        ec2_images = @ec2_client.describe_images({ filters: filters }).images
        ec2_images.each do |ec2_image|
          depends = %w|http://schemas.ogf.org/occi/infrastructure#os_tpl|
          term = os_tpl_list_image_to_term(ec2_image)
          scheme = "#{@options.backend_scheme}/occi/infrastructure/os_tpl#"
          title = ec2_image[:name] || 'unknown'
          location = "/mixin/os_tpl/#{term}/"
          applies = %w|http://schemas.ogf.org/occi/infrastructure#compute|

          os_tpl << Occi::Core::Mixin.new(scheme, term, title, nil, depends, nil, location, applies)
        end

        os_tpl
      end

      # Gets a specific os_tpl mixin instance as Occi::Core::Mixin.
      # Term given as an argument must match the term inside
      # the returned Occi::Core::Mixin instance.
      #
      # @example
      #    os_tpl = os_tpl_get('65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf')
      #        #=> #<Occi::Core::Mixin>
      #
      # @param term [String] OCCI term of the requested os_tpl mixin instance
      # @return [Occi::Core::Mixin, nil] a mixin instance or `nil`
      def os_tpl_get(term)
        # TODO: more effective impl
        os_tpl_list.to_a.select { |m| m.term == term }.first
      end

      private

      def os_tpl_list_image_to_term(ec2_image)
        ec2_image[:image_id]
      end

      def os_tpl_list_term_to_image(term)
        term
      end
    end
  end
end
