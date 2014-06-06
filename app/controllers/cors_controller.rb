# Controller class handling all CORS-related requests.
# Implements a dummy action improving performance for
# requests ignoring HTTP body.
class CorsController < ApplicationController
  # OPTIONS /[*dummy]
  def index
    respond_with(Occi::Collection.new, {})
  end
end
