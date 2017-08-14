module Ext
  class ApplicationResponder < ::ActionController::Responder
    def display_resource
      display resource
    end
    alias to_headers display_resource
    alias to_text display_resource
    alias to_json display_resource
    alias to_uri_list display_resource
  end
end
