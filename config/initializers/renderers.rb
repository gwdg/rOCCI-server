# Render OCCI locations into HTTP body for 'text/uri-list'
ActionController::Renderers.add :uri_list do |obj, _options|
  self.content_type = Mime::Type.lookup_by_extension(:uri_list)
  obj.respond_to?(:join) ? obj.join("\n") : obj.to_s
end

# Render OCCI into HTTP headers for 'text/occi'
ActionController::Renderers.add :headers do |obj, _options|
  self.content_type = Mime::Type.lookup_by_extension(:headers)
  hashified = obj.respond_to?(:to_headers) ? obj.to_headers : obj
  headers.merge! hashified
  '' # body is empty here
end

ActionController::Renderers.add :text do |obj, _options|
  self.content_type = Mime::Type.lookup_by_extension(:text)
  obj.respond_to?(:to_text) ? obj.to_text : obj
end

ActionController::Renderers.add :json do |obj, _options|
  self.content_type = Mime::Type.lookup_by_extension(:json)
  obj.to_json
end
