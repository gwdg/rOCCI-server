class DummyStrategy < ::Warden::Strategies::Base
  def valid?
    true
  end

  def authenticate!
    #fail! :message => "strategies.dummy.failed"
    success! Hash.new
  end
end