module Backends
  module AwsEc2; end
end
Dir.glob(File.join(File.dirname(__FILE__), 'aws_ec2', '*.rb')) { |mod| require mod.chomp('.rb') }
