class UnauthorizedController < ActionController::Metal
  include ActionController::UrlFor
  include ActionController::Redirecting

  def self.call(env)
    @respond ||= action(:respond)
    @respond.call(env)
  end

  def respond
    render status: :unauthorized
  end
end