module AuthenticationStrategies::Helpers
  #
  #
  module YamlHelper

    #
    #
    def read_yaml(path)
      begin
        raise "File does not exist!" unless File.exists?(path)
        YAML.load(ERB.new(File.read(path)).result)
      rescue Exception => err
        raise Errors::ConfigurationParsingError,
              "Failed to parse a YAML file! [#{path}]: #{err.message}"
      end
    end
  end
end
