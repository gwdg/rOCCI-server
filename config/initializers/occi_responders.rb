class ActionController::Responder
  def to_occi_header
    options = {}
    options.merge!(@options)
    options[:occi_header] = @resource

    controller.render options
  end

  def to_text
    options = {}
    options.merge!(@options)
    options[:text] = @resource

    controller.render options
  end

  def to_json
    options = {}
    options.merge!(@options)
    options[:occi_json] = @resource

    controller.render options
  end
  alias_method :to_occi_json, :to_json

  def to_xml
    options = {}
    options.merge!(@options)
    options[:occi_xml] = @resource

    controller.render options
  end
  alias_method :to_occi_xml, :to_xml

  def to_uri_list
    options = {}
    options.merge!(@options)
    options[:uri_list] = @resource

    controller.render options
  end
end
