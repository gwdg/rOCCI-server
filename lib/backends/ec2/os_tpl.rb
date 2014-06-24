module Backends
  module Ec2
    module OsTpl

      DALLI_OS_TPL_KEY = 'ec2_os_tpls'

      # Gets backend-specific `os_tpl` mixins which should be merged
      # into Occi::Model of the server.
      #
      # @example
      #    mixins = os_tpl_list #=> #<Occi::Core::Mixins>
      #    mixins.first #=> #<Occi::Core::Mixin>
      #
      # @return [Occi::Core::Mixins] a collection of mixins
      def os_tpl_list
        os_tpl = nil
        filters = []
        filters << { name: 'image-type', values: ['machine'] }

        unless os_tpl = Backends::Helpers::CachingHelper.load(@dalli_cache, DALLI_OS_TPL_KEY)
          os_tpl = Occi::Core::Mixins.new

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            ec2_images = @ec2_client.describe_images({ filters: filters }).images
            ec2_images.each { |ec2_image| os_tpl << os_tpl_list_mixin_from_image(ec2_image) } if ec2_images
          end

          Backends::Helpers::CachingHelper.save(@dalli_cache, DALLI_OS_TPL_KEY, os_tpl)
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
        filters = []
        filters << { name: 'image-type', values: ['machine'] }
        filters << { name: 'image-id', values: [term] }

        Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
          ec2_images = @ec2_client.describe_images({ filters: filters }).images
          (ec2_images && ec2_images.first) ? os_tpl_list_mixin_from_image(ec2_images.first) : nil
        end
      end

      private

      def os_tpl_list_image_to_term(ec2_image)
        ec2_image[:image_id]
      end

      def os_tpl_list_term_to_image_id(term)
        term
      end

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
