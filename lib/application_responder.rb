class ApplicationResponder < ActionController::Responder
  def to_headers
    custom_merge_and_render :headers
  end

  def to_text
    custom_merge_and_render :text
  end

  def to_json
    custom_merge_and_render :json
  end

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
