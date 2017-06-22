Rails.application.routes.draw do
  ####################################################
  ## Occi::Core::Entity Routes (incl. Default Route)
  ####################################################
  get '/',
      to: 'entity#list',
      constraints: ->(req) { !LEGACY_FORMATS.include?(req.format.symbol) }
  root 'entity#locations'
  delete '/', to: 'entity#delete_all'

  get '/mixin/:parent/:term/',
      to: 'entity#scoped_list',
      constraints: ->(req) { !LEGACY_FORMATS.include?(req.format.symbol) }
  get '/mixin/:parent/:term/', to: 'entity#scoped_locations'

  post '/mixin/:parent/:term/',
       to: 'entity#scoped_execute',
       constraints: ->(req) { req.query_parameters[:action] =~ /^[[:lower:]]+$/ }
  post '/mixin/:parent/:term/',
       to: 'entity#assign_mixin',
       constraints: ->(req) { !req.query_parameters.key?(:action) }

  put '/mixin/:parent/:term/', to: 'entity#update_mixin'

  delete '/mixin/:parent/:term/', to: 'entity#scoped_delete_all'

  ####################################################
  ## Query Interface Routes
  ####################################################
  get '/-/', to: 'server_model#show'
  get '/.well-known/org/ogf/occi/-/', to: 'server_model#show'

  ####################################################
  ## Custom Mixin Routes
  ####################################################

  post '/-/', to: 'mixin#create'
  post '/.well-known/org/ogf/occi/-/', to: 'mixin#create'

  # put '/-/' is undefined in GFD-P-R.185
  # put '/.well-known/org/ogf/occi/-/' is undefined in GFD-P-R.185

  delete '/-/', to: 'mixin#delete'
  delete '/.well-known/org/ogf/occi/-/', to: 'mixin#delete'

  ####################################################
  ## Occi::Core::Resource Routes
  ##  - Occi::Infrastructure::Compute
  ##  - Occi::Infrastructure::Network
  ##  - Occi::Infrastructure::Storage
  ####################################################
  get '/:resource/:id', to: 'resource#show'
  get '/:resource/',
      to: 'resource#list',
      constraints: ->(req) { !LEGACY_FORMATS.include?(req.format.symbol) }
  get '/:resource/', to: 'resource#locations'

  post '/:resource/:id',
       to: 'resource#execute',
       constraints: ->(req) { req.query_parameters[:action] =~ /^[[:lower:]]+$/ }
  post '/:resource/:id', to: 'resource#partial_update'
  post '/:resource/',
       to: 'resource#execute',
       constraints: ->(req) { req.query_parameters[:action] =~ /^[[:lower:]]+$/ }
  post '/:resource/', to: 'resource#create'

  put '/:resource/:id', to: 'resource#update'
  # put '/:resource/' is undefined in GFD-P-R.185

  delete '/:resource/:id', to: 'resource#delete'
  delete '/:resource/', to: 'resource#delete_all'

  ####################################################
  ## Occi::Core::Link Routes
  ##  - Occi::Infrastructure::NetworkInterface
  ##  - Occi::Infrastructure::StorageLink
  ####################################################
  get '/link/:link/:id', to: 'link#show'
  get '/link/:link/',
      to: 'link#list',
      constraints: ->(req) { !LEGACY_FORMATS.include?(req.format.symbol) }
  get '/link/:link/', to: 'link#locations'

  post '/link/:link/:id',
       to: 'link#execute',
       constraints: ->(req) { req.query_parameters[:action] =~ /^[[:lower:]]+$/ }
  post '/link/:link/:id', to: 'link#partial_update'
  post '/link/:link/',
       to: 'link#execute',
       constraints: ->(req) { req.query_parameters[:action] =~ /^[[:lower:]]+$/ }
  post '/link/:link/', to: 'link#create'

  put '/link/:link/:id', to: 'link#update'
  # put '/link/:link/' is undefined in GFD-P-R.185

  delete '/link/:link/:id', to: 'link#delete'
  delete '/link/:link/', to: 'link#delete_all'
end
