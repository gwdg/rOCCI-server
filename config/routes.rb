Rails.application.routes.draw do
  ####################################################
  ## Default Route
  ####################################################
  get '/', to: 'server_model#list', constraints: lambda { |req| !LEGACY_FORMATS.include?(req.format) }
  root 'server_model#locations'

  ####################################################
  ## Query Interface Routes
  ####################################################
  get '/-/', to: 'server_model#show'
  get '/.well-known/org/ogf/occi/-/', to: 'server_model#show'

  post '/-/', to: 'server_model#mixin_create'
  post '/.well-known/org/ogf/occi/-/', to: 'server_model#mixin_create'

  # put '/-/' is undefined in GFD-P-R.185
  # put '/.well-known/org/ogf/occi/-/' is undefined in GFD-P-R.185

  delete '/-/', to: 'server_model#mixin_delete'
  delete '/.well-known/org/ogf/occi/-/', to: 'server_model#mixin_delete'

  ####################################################
  ## Occi::Core::Resource Routes
  ##  - Occi::Infrastructure::Compute
  ##  - Occi::Infrastructure::Network
  ##  - Occi::Infrastructure::Storage
  ####################################################
  get '/:resource/:id', to: 'resource#show'
  get '/:resource/', to: 'resource#locations', constraints: lambda { |req| LEGACY_FORMATS.include? req.format }
  get '/:resource/', to: 'resource#list'

  post '/:resource/:id', to: 'resource#execute', constraints: { query_string: /^action=[[:lower:]]+$/ }
  post '/:resource/:id', to: 'resource#partial_update'
  post '/:resource/', to: 'resource#execute', constraints: { query_string: /^action=[[:lower:]]+$/ }
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
  get '/link/:link/', to: 'link#locations', constraints: lambda { |req| LEGACY_FORMATS.include? req.format }
  get '/link/:link/', to: 'link#list'

  post '/link/:link/:id', to: 'link#execute', constraints: { query_string: /^action=[[:lower:]]+$/ }
  post '/link/:link/:id', to: 'link#partial_update'
  post '/link/:link/', to: 'link#execute', constraints: { query_string: /^action=[[:lower:]]+$/ }
  post '/link/:link/', to: 'link#create'

  put '/link/:link/:id', to: 'link#update'
  # put '/link/:link/' is undefined in GFD-P-R.185

  delete '/link/:link/:id', to: 'link#delete'
  delete '/link/:link/', to: 'link#delete_all'

  ####################################################
  ## Occi::Core::Mixin
  ##  - Occi::Infrastructure::OsTpl
  ##  - Occi::Infrastructure::ResourceTpl
  ##  - Occi::InfrastructureExt::AvailabilityZone
  ####################################################
  get '/mixin/:parent/:term/', to: 'mixin#scoped_locations', constraints: lambda { |req| LEGACY_FORMATS.include? req.format }
  get '/mixin/:parent/:term/', to: 'mixin#scoped_list'

  post '/mixin/:parent/:term/', to: 'mixin#scoped_execute', constraints: { query_string: /^action=[[:lower:]]+$/ }
  post '/mixin/:parent/:term/', to: 'mixin#assign'

  put '/mixin/:parent/:term/', to: 'mixin#update'

  delete '/mixin/:parent/:term/', to: 'mixin#scoped_delete_all'
end
