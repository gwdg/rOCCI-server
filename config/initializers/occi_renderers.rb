# Render OCCI into HTTP headers for 'text/occi'
ActionController::Renderers.add :occi_header do |obj, options|
  self.content_type ||= Mime::OCCI_HEADER
  self.headers.merge!(obj.to_header) if obj.respond_to?(:to_header)

  ""
end

# Render OCCI into HTTP body for 'text/plain'
ActionController::Renderers.add :text do |obj, options|
  self.content_type ||= Mime::TEXT
  obj.respond_to?(:to_text) ? obj.to_text : obj
end

# Render OCCI into HTTP body for 'application/occi+json'
ActionController::Renderers.add :occi_json do |obj, options|
  self.content_type ||= Mime::OCCI_JSON
  obj.respond_to?(:to_json) ? obj.to_json : "{ 'message': 'Object cannot be rendered as JSON!' }"
end

# Render OCCI into HTTP body for 'application/occi+xml'
ActionController::Renderers.add :occi_xml do |obj, options|
  self.content_type ||= Mime::OCCI_XML
  obj.respond_to?(:to_xml) ? obj.to_xml : "<message>Object cannot be rendered as XML!</message>"
end

# Render OCCI locations into HTTP body for 'text/uri-list'
ActionController::Renderers.add :uri_list do |obj, options|
  self.content_type ||= Mime::URI_LIST

  case
  when obj.respond_to?(:location)
    obj.location
  when obj.respond_to?(:resources)
    obj.resources.to_a.collect { |o| o.location }.to_a.join("\n")
  when obj.kind_of?(Occi::Core::Resources)
    obj.to_a.collect { |o| o.location }.to_a.join("\n")
  else
    ""
  end
end