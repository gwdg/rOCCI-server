module Ext
  class ApplicationResponder < ::ActionController::Responder
    # :nodoc:
    def format
      request.format.symbol
    end

    # :nodoc:
    def respond
      display resource
    end
  end
end
