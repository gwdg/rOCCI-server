class ApplicationResponder < ActionController::Responder
  def to_occi_header
    custom_merge_and_render :occi_header
  end

  def to_text
    custom_merge_and_render :text
  end

  def to_json
    custom_merge_and_render :occi_json
  end
  alias_method :to_occi_json, :to_json

  def to_xml
    custom_merge_and_render :occi_xml
  end
  alias_method :to_occi_xml, :to_xml

  def to_uri_list
    custom_merge_and_render :uri_list
  end

  private

  def custom_merge_and_render(mime_type, options = {})
    options.merge!(@options)
    options[mime_type] = @resource

    controller.render options
  end
end
