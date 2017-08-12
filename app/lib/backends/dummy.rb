module Backends
  # Namespace containing classes and modules of the Dummy backend. This backend is meant for testing
  # purposes only. It provides a minimal implementation of the backend API, changes are not persistent,
  # and return minimalistic entity instances.
  module Dummy; end
end
Dir.glob(File.join(File.dirname(__FILE__), 'dummy', '*.rb')) { |mod| require mod.chomp('.rb') }
