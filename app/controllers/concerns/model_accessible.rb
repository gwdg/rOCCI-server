module ModelAccessible
  # Model flavors loaded when initializing server model
  MODEL_FLAVORS = %w[core infrastructure infrastructure_ext].freeze

  # Returns fully initialized server model.
  #
  # @return [Occi::Core::Model] server model
  def server_model
    return @_server_model if @_server_model

    bootstrap_server_model!
    extend_server_model!
    @_server_model
  end

  # Returns server model with pre-loaded content.
  #
  # @return [Occi::Core::Model] partially initialized server model
  def bootstrap_server_model!
    logger.debug "Bootstrapping server model with #{MODEL_FLAVORS}"
    @_server_model = Occi::InfrastructureExt::Model.new
    MODEL_FLAVORS.each { |flv| @_server_model.send "load_#{flv}!" }
    @_server_model
  end

  # Adds backend-specific content to partially initialized server model.
  #
  # @return [Occi::Core::Model] fully initialized server model
  def extend_server_model!
    logger.debug 'Extending server model with backend mixins'
    backend_proxy_for('model_extender').populate! @_server_model
  end
end
