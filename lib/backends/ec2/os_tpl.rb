module Backends
  module Ec2
    module OsTpl

      DALLI_OS_TPL_KEY = 'ec2_os_tpls'
      IMAGE_FILTERING_POLICIES_OWNED = ['only_owned', 'owned_and_listed'].freeze
      IMAGE_FILTERING_POLICIES_LISTED = ['only_listed', 'owned_and_listed'].freeze

      # Gets backend-specific `os_tpl` mixins which should be merged
      # into Occi::Model of the server.
      #
      # @example
      #    mixins = os_tpl_list #=> #<Occi::Core::Mixins>
      #    mixins.first #=> #<Occi::Core::Mixin>
      #
      # @return [Occi::Core::Mixins] a collection of mixins
      # @effects Gets status of machine images
      def os_tpl_list
        filters = []
        filters << { name: 'image-type', values: ['machine'] }
        filters << { name: 'image-id', values: @image_filtering_image_list } if IMAGE_FILTERING_POLICIES_LISTED.include?(@image_filtering_policy)
        owners = IMAGE_FILTERING_POLICIES_OWNED.include?(@image_filtering_policy) ? [ 'self' ] : nil

        ec2_images_ary = nil
        unless ec2_images_ary = Backends::Helpers::CachingHelper.load(@dalli_cache, DALLI_OS_TPL_KEY)
          ec2_images_ary = []

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            ec2_images = if owners
              @ec2_client.describe_images(filters: filters, owners: owners).images
            else
              @ec2_client.describe_images(filters: filters).images
            end

            ec2_images.each { |ec2_image| ec2_images_ary << { image_id: ec2_image[:image_id], name: ec2_image[:name] } } if ec2_images
          end

          Backends::Helpers::CachingHelper.save(@dalli_cache, DALLI_OS_TPL_KEY, ec2_images_ary)
        end

        os_tpls = Occi::Core::Mixins.new
        ec2_images_ary.each { |ec2_image| os_tpls << os_tpl_list_mixin_from_image(ec2_image) }

        os_tpls
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
      # @effects Gets status of a given machine image
      def os_tpl_get(term)
        filters = []
        filters << { name: 'image-type', values: ['machine'] }
        filters << { name: 'image-id', values: [term] }

        Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
          ec2_images = @ec2_client.describe_images(filters: filters).images
          (ec2_images && ec2_images.first) ? os_tpl_list_mixin_from_image(ec2_images.first) : nil
        end
      end

      #
      #
      def os_tpl_list_image_to_term(ec2_image)
        ec2_image[:image_id]
      end

      #
      #
      def os_tpl_list_term_to_image_id(term)
        term
      end

      #
      #
      def os_tpl_list_mixin_from_image(ec2_image)
        depends = %w|http://schemas.ogf.org/occi/infrastructure#os_tpl|
        term = os_tpl_list_image_to_term(ec2_image)
        scheme = "#{@options.backend_scheme}/occi/infrastructure/os_tpl#"
        title = ec2_image[:name] || 'unknown'
        location = "/mixin/os_tpl/#{term}/"
        applies = %w|http://schemas.ogf.org/occi/infrastructure#compute|

        Occi::Core::Mixin.new(scheme, term, title, nil, depends, nil, location, applies)
      end
    end
  end
end
