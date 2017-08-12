module Backends
  # Namespace for classes and modules of the OpenNebula bakcend. It provides a feature-complete implementation
  # of the bakcned API and affects the underlying OpenNebula cloud.
  module Opennebula; end
end
Dir.glob(File.join(File.dirname(__FILE__), 'opennebula', '*.rb')) { |mod| require mod.chomp('.rb') }
