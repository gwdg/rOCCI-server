require "hashie/mash"
require 'optparse'

module OCCI
  module Helper
    class OcciServerOptions

      def initialize()
        @_options = Hashie::Mash.new

        @_options.frontend = "http"

        _define_parser
      end

      # @param [Arguable] args
      def _parse(args)
        begin
          @opts.parse!(args)
        rescue Exception => ex
          puts ex.message.capitalize
          puts @opts
          exit!
        end
      end

      def method_missing(name, *args, &block)
        @_options[name.to_sym] || fail(NoMethodError, "unknown option #{name}", caller)
      end

      private ##########################################################################################################

      def _define_parser
        @opts = OptionParser.new do |opts|
          opts.banner = "Usage: occi_server [OPTIONS]"

          opts.separator ""
          opts.separator "Options:"

          opts.on("-f",
                  "--frontend FRONTEND",
                  "Frontend for the OCCI Server, default to #{@_options.frontend}") do |frontend|
            @_options.frontend = frontend
          end
        end
      end
    end
  end
end
