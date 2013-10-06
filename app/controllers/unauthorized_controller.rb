class UnauthorizedController < ActionController::Metal
  include ActionController::UrlFor
  include ActionController::Redirecting
  include ActionController::Rendering
  include ActionController::Renderers::All

  def self.call(env)
    @respond ||= action(:respond)
    @respond.call(env)
  end

  def respond
    render status: :unauthorized, nothing: true
  end
end