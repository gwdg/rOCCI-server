# Render OCCI locations into HTTP body for 'text/uri-list'
ActionController::Renderers.add :uri_list do |obj, _options|
  self.content_type = Mime::Type.lookup_by_extension(:uri_list)
  obj = obj.to_a if obj.respond_to?(:to_a)
  obj.join "\n"
end

# Render OCCI into HTTP headers for 'text/occi'
ActionController::Renderers.add :headers do |obj, _options|
  self.content_type = Mime::Type.lookup_by_extension(:headers)
  headers.merge! obj.to_headers
  '' # body is empty here
end

ActionController::Renderers.add :text do |obj, _options|
  self.content_type = Mime::Type.lookup_by_extension(:text)
  obj.to_text
end

ActionController::Renderers.add :json do |obj, _options|
  self.content_type = Mime::Type.lookup_by_extension(:json)
  obj.to_json
end
