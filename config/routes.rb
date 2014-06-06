ROCCIServer::Application.routes.draw do
  ####################################################
  ## Support for CORS (HTTP OPTIONS method)
  ####################################################
  match '/', to: 'cors#index', via: :options
  match '/*dummy', to: 'cors#index', via: :options

  ####################################################
  ## Discovery interface
  ####################################################
  get '/-/', to: 'occi_model#show', as: 'occi_model'
  get '/.well-known/org/ogf/occi/-/', to: 'occi_model#show'

  post '/-/', to: 'occi_model#create', as: 'add_mixin'
  post '/.well-known/org/ogf/occi/-/', to: 'occi_model#create'

  # put '/-/' is undefined in GFD-P-R.185
  # put '/.well-known/org/ogf/occi/-/' is undefined in GFD-P-R.185

  delete '/-/', to: 'occi_model#delete', as: 'delete_mixin'
  delete '/.well-known/org/ogf/occi/-/', to: 'occi_model#delete'

  ####################################################
  ## Occi::Infrastructure::Compute
  ####################################################
  get '/compute/:id', to: 'compute#show', as: 'compute'
  get '/compute/', to: 'compute#index', as: 'computes'

  post '/compute/:id', to: 'compute#trigger', constraints: { query_string: /^action=\S+$/ }
  post '/compute/:id', to: 'compute#partial_update', as: 'partial_update_compute'
  post '/compute/', to: 'compute#trigger', constraints: { query_string: /^action=\S+$/ }
  post '/compute/', to: 'compute#create', as: 'new_compute'

  put '/compute/:id', to: 'compute#update', as: 'update_compute'
  # put '/compute/' is undefined in GFD-P-R.185

  delete '/compute/:id', to: 'compute#delete', as: 'delete_compute'
  delete '/compute/', to: 'compute#delete', as: 'delete_computes'

  ####################################################
  ## Occi::Infrastructure::Network
  ####################################################
  get '/network/:id', to: 'network#show', as: 'network'
  get '/network/', to: 'network#index', as: 'networks'

  post '/network/:id', to: 'network#trigger', constraints: { query_string: /^action=\S+$/ }
  post '/network/:id', to: 'network#partial_update', as: 'partial_update_network'
  post '/network/', to: 'network#trigger', constraints: { query_string: /^action=\S+$/ }
  post '/network/', to: 'network#create', as: 'new_network'

  put '/network/:id', to: 'network#update', as: 'update_network'
  # put '/network/' is undefined in GFD-P-R.185

  delete '/network/:id', to: 'network#delete', as: 'delete_network'
  delete '/network/', to: 'network#delete', as: 'delete_networks'

  ####################################################
  ## Occi::Infrastructure::Storage
  ####################################################
  get '/storage/:id', to: 'storage#show', as: 'storage'
  get '/storage/', to: 'storage#index', as: 'storages'

  post '/storage/:id', to: 'storage#trigger', constraints: { query_string: /^action=\S+$/ }
  post '/storage/:id', to: 'storage#partial_update', as: 'partial_update_storage'
  post '/storage/', to: 'storage#trigger', constraints: { query_string: /^action=\S+$/ }
  post '/storage/', to: 'storage#create', as: 'new_storage'

  put '/storage/:id', to: 'storage#update', as: 'update_storage'
  # put '/storage/' is undefined in GFD-P-R.185

  delete '/storage/:id', to: 'storage#delete', as: 'delete_storage'
  delete '/storage/', to: 'storage#delete', as: 'delete_storages'

  ####################################################
  ## Occi::Infrastructure::NetworkInterface
  ####################################################
  get '/link/networkinterface/:id', to: 'networkinterface#show', as: 'networkinterface'

  post '/link/networkinterface/', to: 'networkinterface#create', as: 'new_networkinterface'

  delete '/link/networkinterface/:id', to: 'networkinterface#delete', as: 'delete_networkinterface'

  ####################################################
  ## Occi::Infrastructure::StorageLink
  ####################################################
  get '/link/storagelink/:id', to: 'storagelink#show', as: 'storagelink'

  post '/link/storagelink/', to: 'storagelink#create', as: 'new_storagelink'

  delete '/link/storagelink/:id', to: 'storagelink#delete', as: 'delete_storagelink'

  ####################################################
  ## Occi::Infrastructure::OsTpl
  ####################################################
  get '/mixin/os_tpl(/:term)', to: 'os_tpl#index', as: 'os_tpl'

  post '/mixin/os_tpl(/:term)', to: 'os_tpl#trigger', constraints: { query_string: /^action=\S+$/ }

  ####################################################
  ## Occi::Infrastructure::ResourceTpl
  ####################################################
  get '/mixin/resource_tpl(/:term)', to: 'resource_tpl#index', as: 'resource_tpl'

  post '/mixin/resource_tpl(/:term)', to: 'resource_tpl#trigger', constraints: { query_string: /^action=\S+$/ }

  ####################################################
  ## Occi::Core::Mixin (user-defined mixins)
  ####################################################
  get '/mixin/*term/', to: 'mixin#index', as: 'mixin'

  post '/mixin/*term/', to: 'mixin#trigger', constraints: { query_string: /^action=\S+$/ }
  post '/mixin/*term/', to: 'mixin#assign', as: 'assign_mixin'

  put '/mixin/*term/', to: 'mixin#update', as: 'update_mixin'

  delete '/mixin/*term/', to: 'mixin#delete', as: 'unassign_mixin'

  ####################################################
  ## Default route
  ####################################################
  root 'occi_model#index'
end
