# Render OCCI into HTTP headers for 'text/occi'
ActionController::Renderers.add :occi_header do |obj, options|
  self.content_type ||= Mime::OCCI_HEADER

  if options[:flag] == :link_only
    self.headers['Location'] = obj
    "OK"
  else
    self.headers.merge!(obj.to_header) if obj.respond_to?(:to_header)
    ""
  end
end

# Render OCCI into HTTP body for 'text/plain'
ActionController::Renderers.add :text do |obj, options|
  self.content_type ||= Mime::TEXT

  if options[:flag] == :link_only
    "X-OCCI-Location: #{obj}"
  else
    obj.respond_to?(:to_text) ? obj.to_text : obj
  end
end

# Render OCCI into HTTP body for 'application/occi+json'
ActionController::Renderers.add :occi_json do |obj, options|
  self.content_type ||= Mime::OCCI_JSON

  if options[:flag] == :link_only
    "{ 'Location': '#{obj}' }"
  else
    if obj.respond_to?(:to_json)
      obj = case obj
            when Occi::Core::Resources
              c = Occi::Collection.new
              c.resources = obj
              c
            when Occi::Core::Links
              c = Occi::Collection.new
              c.links = obj
              c
            when Occi::Core::Mixins
              c = Occi::Collection.new
              c.mixins = obj
              c
            when Occi::Core::Actions
              c = Occi::Collection.new
              c.actions = obj
              c
            when Occi::Core::Kinds
              c = Occi::Collection.new
              c.kinds = obj
              c
            else
              unless obj.kind_of? Occi::Collection
                Occi::Collection.new << obj
              else
                obj
              end
            end

      obj.to_json
    else
      "{ 'message': 'Object cannot be rendered as JSON!' }"
    end
  end
end

# Render OCCI into HTTP body for 'application/occi+xml'
ActionController::Renderers.add :occi_xml do |obj, options|
  self.content_type ||= Mime::OCCI_XML

  if options[:flag] == :link_only
    "<location>#{obj}</location>"
  else
    obj.respond_to?(:to_xml) ? obj.to_xml : "<message>Object cannot be rendered as XML!</message>"
  end
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
  when obj.kind_of?(Array)
    obj.join("\n")
  else
    ""
  end
end