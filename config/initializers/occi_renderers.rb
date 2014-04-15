# Render OCCI into HTTP headers for 'text/occi'
ActionController::Renderers.add :occi_header do |obj, options|
  self.content_type ||= Mime::OCCI_HEADER

  if options[:flag] == :link_only
    headers['Location'] = obj
    'OK'
  elsif options[:flag] == :links_only
    headers['Location'] = obj.join(',')
    ''
  elsif obj.respond_to?(:to_header)
    headers.merge!(obj.to_header)
    ''
  elsif obj.kind_of?(Hash)
    headers.merge!(obj)
    ''
  else
    self.status = 500
    'Object cannot be rendered into HTTP headers!'
  end
end

# Render OCCI into HTTP body for 'text/plain'
ActionController::Renderers.add :text do |obj, options|
  self.content_type ||= Mime::TEXT

  if options[:flag] == :link_only
    "X-OCCI-Location: #{obj}"
  elsif options[:flag] == :links_only
    obj.collect { |link| "X-OCCI-Location: #{link}" }.join("\n")
  else
    obj.respond_to?(:to_text) ? obj.to_text : obj.to_s
  end
end

# Render OCCI into HTTP body for 'application/occi+json'
ActionController::Renderers.add :occi_json do |obj, options|
  self.content_type ||= Mime::OCCI_JSON

  if options[:flag] == :link_only
    headers['Location'] = obj
    'OK'
  elsif obj.respond_to?(:to_json)
    obj.to_json
  else
    self.status = 500
    "{ 'message': 'Object cannot be rendered as JSON!' }"
  end
end

# Render OCCI into HTTP body for 'application/occi+xml'
ActionController::Renderers.add :occi_xml do |obj, options|
  self.content_type ||= Mime::OCCI_XML

  if options[:flag] == :link_only
    headers['Location'] = obj
    'OK'
  elsif obj.respond_to?(:to_xml)
    obj.to_xml
  else
    self.status = 500
    '<message>Object cannot be rendered as XML!</message>'
  end
end

# Render OCCI locations into HTTP body for 'text/uri-list'
ActionController::Renderers.add :uri_list do |obj, options|
  self.content_type ||= Mime::URI_LIST

  case
  when obj.respond_to?(:location)
    obj.location
  when obj.respond_to?(:resources)
    obj.resources.to_a.map { |o| o.location }.join("\n")
  when obj.respond_to?(:join)
    obj.join("\n")
  else
    self.status = 500
    'Object cannot be rendered as a list of URIs!'
  end
end
