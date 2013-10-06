module AuthenticationStrategies
  class DummyStrategy < ::Warden::Strategies::Base
    def valid?
      true
    end

    def authenticate!
      #fail! :message => "Unauthorized!"
      success! Hash.new
    end
  end
end