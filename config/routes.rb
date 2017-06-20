Rails.application.routes.draw do
  ####################################################
  ## Occi::Core::Entity Routes (incl. Default Route)
  ####################################################
  get '/',
      to: 'entity#list',
      constraints: RoutingConstraints.build(%i[non_legacy])
  get '/',
      to: 'entity#locations',
      constraints: RoutingConstraints.build(%i[legacy])

  post '/',
       to: 'entity#execute_all',
       constraints: RoutingConstraints.build(%i[action])

  delete '/', to: 'entity#delete_all'

  root 'entity#locations'

  get '/mixin/:parent/:term/',
      to: 'entity#scoped_list',
      constraints: RoutingConstraints.build(%i[non_legacy mixin])
  get '/mixin/:parent/:term/',
      to: 'entity#scoped_locations',
      constraints: RoutingConstraints.build(%i[legacy mixin])

  post '/mixin/:parent/:term/',
       to: 'entity#scoped_execute_all',
       constraints: RoutingConstraints.build(%i[action mixin])
  post '/mixin/:parent/:term/',
       to: 'entity#assign_mixin',
       constraints: RoutingConstraints.build(%i[non_action mixin])

  put '/mixin/:parent/:term/',
      to: 'entity#update_mixin',
      constraints: RoutingConstraints.build(%i[mixin])

  delete '/mixin/:parent/:term/',
         to: 'entity#scoped_delete_all',
         constraints: RoutingConstraints.build(%i[mixin])

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
  get '/:resource/:id',
      to: 'resource#show',
      constraints: RoutingConstraints.build(%i[resource])
  get '/:resource/',
      to: 'resource#list',
      constraints: RoutingConstraints.build(%i[non_legacy resource])
  get '/:resource/',
      to: 'resource#locations',
      constraints: RoutingConstraints.build(%i[legacy resource])

  post '/:resource/:id',
       to: 'resource#execute',
       constraints: RoutingConstraints.build(%i[action resource])
  post '/:resource/:id',
       to: 'resource#partial_update',
       constraints: RoutingConstraints.build(%i[non_action resource])
  post '/:resource/',
       to: 'resource#execute_all',
       constraints: RoutingConstraints.build(%i[action resource])
  post '/:resource/',
       to: 'resource#create',
       constraints: RoutingConstraints.build(%i[non_action resource])

  put '/:resource/:id',
      to: 'resource#update',
      constraints: RoutingConstraints.build(%i[resource])
  # put '/:resource/' is undefined in GFD-P-R.185

  delete '/:resource/:id',
         to: 'resource#delete',
         constraints: RoutingConstraints.build(%i[resource])
  delete '/:resource/',
         to: 'resource#delete_all',
         constraints: RoutingConstraints.build(%i[resource])

  ####################################################
  ## Occi::Core::Link Routes
  ##  - Occi::Infrastructure::NetworkInterface
  ##  - Occi::Infrastructure::StorageLink
  ####################################################
  get '/link/:link/:id',
      to: 'link#show',
      constraints: RoutingConstraints.build(%i[link])
  get '/link/:link/',
      to: 'link#list',
      constraints: RoutingConstraints.build(%i[non_legacy link])
  get '/link/:link/',
      to: 'link#locations',
      constraints: RoutingConstraints.build(%i[legacy link])

  post '/link/:link/:id',
       to: 'link#execute',
       constraints: RoutingConstraints.build(%i[action link])
  post '/link/:link/:id',
       to: 'link#partial_update',
       constraints: RoutingConstraints.build(%i[non_action link])
  post '/link/:link/',
       to: 'link#execute_all',
       constraints: RoutingConstraints.build(%i[action link])
  post '/link/:link/',
       to: 'link#create',
       constraints: RoutingConstraints.build(%i[non_action link])

  put '/link/:link/:id',
      to: 'link#update',
      constraints: RoutingConstraints.build(%i[link])
  # put '/link/:link/' is undefined in GFD-P-R.185

  delete '/link/:link/:id',
         to: 'link#delete',
         constraints: RoutingConstraints.build(%i[link])
  delete '/link/:link/',
         to: 'link#delete_all',
         constraints: RoutingConstraints.build(%i[link])
end
