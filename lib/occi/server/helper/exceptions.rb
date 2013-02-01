module Occi
  module Server
    module Helper
      class OcciServerError < RuntimeError;
      end
      class BackendError < Occi::Exceptions::OcciServerError;
      end
      class FrontendError < Occi::Exceptions::OcciServerError;
      end
      class AmqpError < Occi::Exceptions::FrontendError;
      end
      class HttpError < Occi::Exceptions::FrontendError;
      end
    end
  end
end
