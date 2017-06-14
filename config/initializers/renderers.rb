# Render OCCI into HTTP headers for 'text/occi'
ActionController::Renderers.add :headers do |obj, options|
  self.content_type ||= Mime::OCCI_HEADERS
  obj.to_headers
end

# Render OCCI locations into HTTP body for 'text/uri-list'
ActionController::Renderers.add :uri_list do |obj, options|
  self.content_type ||= Mime::URI_LIST
  obj.join("\n")
end
