module Backends
  module Dummy; end
end
Dir.glob(File.join(File.dirname(__FILE__), 'dummy', '*.rb')) { |mod| require mod.chomp('.rb') }
