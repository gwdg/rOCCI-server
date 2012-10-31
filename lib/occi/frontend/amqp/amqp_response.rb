require "occi/frontend/base/base_response"
require "erb"

module OCCI
  module Frontend
    module Amqp
      class AmqpResponse < OCCI::Frontend::Base::BaseResponse
        attr_reader   :routing_key
        # @param [OCCI::Frontend::Http:HttpRequest] request
        # @param [Hash] metadata
        def initialize(request, metadata)
          @status       = 200
          @routing_key  = metadata.reply_to
          @request      = request
          @media_type   = request.accept
        end

        # @param [Integer] code
        # @param [String] message
        def error (code , message = "")
          @message  = message
          @status     = code
          @is_error = true
        end

        # @param [Integer] code
        # @param [String] message
        def halt (code , message = "")
          @message  = message
          @status     = code
          @is_error = true
        end

        # @describe generates payload for the response
        # @return [String]
        def generate_output()
          if @is_error
            @media_type  = "text/plain"
            return @message
          end

          @collection ||= OCCI::Collection.new
          @locations  ||= Array.new

          case @media_type
            when 'text/occi', 'text/plain', '*/*'
              template = ERB.new( File.new(File.dirname(__FILE__) + "/../../../../views/collection.erb").read)
              return template.result(binding)
            when 'application/occi+json', 'application/json'
              return @collection.to_json
            when 'application/occi+xml'
              #TODO to_xml is not implemented
              @media_type = "text/plain"
              return "OCCI+XML is not implemented yet"
            #return @collection.to_xml(:root => "collection")
            when 'application/xml'
              return XmlSimple.xml_out(@collection.as_json, 'RootName' => 'occi')
            when 'text/uri-list'
              return @locations.join("\n")
            else
              content = "Accept.Content_Type (#{ @media_type }) not supported"
              @media_type = "text/plain"
              return content
          end
        end

        # @return [Array]
        def reply_options
          return {
              :routing_key    => @routing_key,
              :content_type   => @media_type,
              :correlation_id => @request.message_id,
              :headers        => header
          }
        end

        # @return [Array]
        def header
          return {
              :status_code => @status,
              :path_info   => @request.path_info,
              :is_error    => @is_error
          }
        end
      end
    end
  end
end