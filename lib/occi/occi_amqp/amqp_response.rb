module OCCI
  module OCCI_AMQP
    class AmqpResponse
      attr_accessor :status_code, :payload, :locations, :collection
      attr_reader   :routing_key

      def initialize(request, metadata)
        @status_code  = "404"
        @routing_key  = metadata.reply_to
        @request      = request
        @content_type = request.accept
      end

      def error (code , message = "")
        @message     = message
        @status_code = code
        @is_error    = true
      end

      def generate_output()

        if @is_error
          @content_type = "text/plain"
          return @message
        end

        @collection ||= OCCI::Collection.new
        @locations  ||= Array.new

        case @content_type
          when 'text/occi', 'text/plain', '*/*'
            template = ERB.new( File.new(File.dirname(__FILE__) + "/../../../views/collection.erb").read)
            return template.result(binding)
          when 'application/occi+json', 'application/json'
            return @collection.to_json
          when 'application/occi+xml'
            #TODO to_xml is not implemented
            @content_type = "text/plain"
            return "OCCI+XML is not implemented yet"
            #return @collection.to_xml(:root => "collection")
          when 'application/xml'
            return XmlSimple.xml_out(@collection.as_json, 'RootName' => 'occi')
          when 'text/uri-list'
            return @locations.join("\n")
          else
            content       = "Accept.Content_Type (#{ @content_type }) not supported"
            @content_type = "text/plain"
            return content
        end
      end

      def reply_options
         return {
             :routing_key    => @routing_key,
             :content_type   => @content_type,
             :correlation_id => @request.message_id,
             :headers        => header
         }
      end

      def header
        return {
            :status_code => @status_code,
            :path_info   => @request.path_info
        }
      end

    end
  end
end
