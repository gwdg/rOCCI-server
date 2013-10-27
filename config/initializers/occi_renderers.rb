ActionController::Renderers.add :occi_header do |obj, options|
  self.content_type ||= Mime::OCCI_HEADER
  obj.respond_to?(:to_occi_header) ? obj.to_occi_header(options) : obj
end

ActionController::Renderers.add :occi_json do |obj, options|
  self.content_type ||= Mime::OCCI_JSON
  obj.respond_to?(:to_occi_json) ? obj.to_occi_json(options) : obj
end

ActionController::Renderers.add :occi_xml do |obj, options|
  self.content_type ||= Mime::OCCI_XML
  obj.respond_to?(:to_occi_xml) ? obj.to_occi_xml(options) : obj
end