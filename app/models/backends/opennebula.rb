module Backends
  module Opennebula; end
end
Dir.glob(File.join(File.dirname(__FILE__), 'opennebula', '*.rb')) { |mod| require mod.chomp('.rb') }
