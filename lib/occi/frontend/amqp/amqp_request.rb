require "occi/frontend/base/base_request"
require "cgi"

module OCCI
  module Frontend
    module Amqp
      class AmqpRequest < OCCI::Frontend::Base::BaseRequest
        attr_reader :message_id, :type  #sollte in request_method umbenannt werden

        # @param [String] payload content of the message
        # @param [Hash] metadata information about the message
        def initialize(metadata, payload)
          parse(metadata, payload)
        end

        # @describe grep header from metadata
        # @return [Array]
        def env
          return {
              'HTTP_X_OCCI_ATTRIBUTE' => @header["X_OCCI_ATTRIBUTE"],
              'HTTP_X_OCCI_LOCATION'  => @header["X_OCCI_LOCATION"],
              'HTTP_CATEGORY'         => @header["CATEGORY"],
              'HTTP_LINK'             => @header["LINK"],
          }
        end

        private
        ##################################################################################################################

        # @describe parse information from the requested message
        # @param [Hash] metadata
        # @param [String] payload content of the message
        def parse(metadata, payload)
          @body         = payload
          @params       = parse_params(metadata.headers["path_info"])
          @path_info    = metadata.headers["path_info"].split("?")[0]
          @accept       = metadata.headers["accept"]
          @type         = metadata.type
          @media_type   = metadata.content_type || "occi/text"
          @message_id   = metadata.message_id

          @header = metadata.headers.inject({}) do |hash, keys|
            hash[keys[0].upcase] = keys[1]
            hash
          end

          #TODO find baseurl
          @base_url         = "http://localhost:9292"
          @script_name      = ""
        end

        # @describe parse query from the given path_info
        # @param [String] path_info
        # @return [Hash]
        def parse_params(path_info)
          query  = path_info.split("?")[1]
          params = Hash.new

          if query != nil && query.size > 1
            params = CGI::parse(query).inject({}) do |hash, keys|
              if keys[1].size < 2
                hash[keys[0].to_sym] = keys[1].first
              else
                hash[keys[0].to_sym] = keys[1]
              end
              hash
            end
          end

          return params
        end
      end
    end
  end
end