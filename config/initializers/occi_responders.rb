class ActionController::Responder
  def to_occi_header
    controller.render :occi_header => @resource
  end

  def to_occi_json
    controller.render :occi_json => @resource
  end

  def to_xml
    controller.render :occi_xml => @resource
  end

  def to_occi_xml
    controller.render :occi_xml => @resource
  end

  def to_uri_list
    controller.render :uri_list => @resource
  end
end