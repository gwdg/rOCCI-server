module Backends
  module OpenNebula; end
end
Dir.glob(File.join(File.dirname(__FILE__), 'open_nebula', '*.rb')) { |mod| require mod.chomp('.rb') }
