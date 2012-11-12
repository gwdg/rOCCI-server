module OCCI
  module Frontend
    module Base
      class BaseRequest
        attr_reader :body, :path_info, :media_type, :base_url, :script_name, :params, :accept

        def env
          raise "env is not implemented"
        end
      end
    end
  end
end