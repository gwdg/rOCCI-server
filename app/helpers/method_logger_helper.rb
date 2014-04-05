# Module housing a logging helper. Once included in a module or a class
# all method inputs and outputs will be automatically logged.
module MethodLoggerHelper
  # Extends private and public methods of the target module/class with
  # logging facilities. Inputs and outputs will be automatically logged
  # when running with DEBUG log level.
  #
  # @param base [Module, Class] a reference to the target module/class
  def self.included(base)
    # Load instance methods directly from the given class
    methods = base.instance_methods(false) + base.private_instance_methods(false)

    # If this is used in Backend, we have to manually include methods from BackendApi
    # since they are in separate modules
    api_ancestors = base.ancestors.select { |anc| anc.to_s.start_with?('BackendApi') }
    api_ancestors.each { |anc| methods << anc.instance_methods(false) }

    # All methods are equal
    methods.flatten!

    # Do some magic and define proxy methods on-the-fly
    base.class_eval do
      methods.each do |method_name|
        original_method = instance_method(method_name)

        define_method(method_name) do |*args, &block|
          Rails.logger.debug "---> #{base}##{method_name}(#{args.inspect})"

          return_value = original_method.bind(self).call(*args, &block)
          Rails.logger.debug "<--- #{base}##{method_name} #=> #{return_value.inspect}"
          return_value
        end
      end
    end
  end
end
