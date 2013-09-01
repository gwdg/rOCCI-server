ROCCIServer::Application.routes.draw do
  ####################################################
  ## Discovery interface
  ####################################################
  get '/-/', to: 'model#show', as: 'model'
  get '/.well-known/org/ogf/occi/-/', to: 'model#show'

  post '/-/', to: 'model#create', as: 'add_mixin'
  post '/.well-known/org/ogf/occi/-/', to: 'model#create'

  #put '/-/' is undefined in GFD-P-R.185
  #put '/.well-known/org/ogf/occi/-/' is undefined in GFD-P-R.185
  
  delete '/-/', to: 'model#delete', as: 'delete_mixin'
  delete '/.well-known/org/ogf/occi/-/', to: 'model#delete'

  ####################################################
  ## Occi::Infrastructure::Compute
  ####################################################
  get '/compute/:id', to: 'compute#show', as: 'compute'
  get '/compute/', to: 'compute#index', as: 'computes'

  post '/compute/:id', to: 'compute#trigger', constraints: { query_string: /^\?action=/ }
  post '/compute/:id', to: 'compute#update', as: 'update_compute'
  post '/compute/', to: 'compute#trigger', constraints: { query_string: /^\?action=/ }
  post '/compute/', to: 'compute#create', as: 'new_compute'

  put '/compute/:id', to: 'compute#update'
  #put '/compute/' is undefined in GFD-P-R.185

  delete '/compute/:id', to: 'compute#delete', as: 'delete_compute'
  delete '/compute/', to: 'compute#delete', as: 'delete_computes'

  ####################################################
  ## Occi::Infrastructure::Network
  ####################################################
  get '/network/:id', to: 'network#show', as: 'network'
  get '/network/', to: 'network#index', as: 'networks'

  post '/network/:id', to: 'network#trigger', constraints: { query_string: /^\?action=/ }
  post '/network/:id', to: 'network#update', as: 'update_network'
  post '/network/', to: 'network#trigger', constraints: { query_string: /^\?action=/ }
  post '/network/', to: 'network#create', as: 'new_network'

  put '/network/:id', to: 'network#update'
  #put '/network/' is undefined in GFD-P-R.185

  delete '/network/:id', to: 'network#delete', as: 'delete_network'
  delete '/network/', to: 'network#delete', as: 'delete_networks'

  ####################################################
  ## Occi::Infrastructure::Storage
  ####################################################
  get '/storage/:id', to: 'storage#show', as: 'storage'
  get '/storage/', to: 'storage#index', as: 'storages'

  post '/storage/:id', to: 'storage#trigger', constraints: { query_string: /^\?action=/ }
  post '/storage/:id', to: 'storage#update', as: 'update_storage'
  post '/storage/', to: 'storage#trigger', constraints: { query_string: /^\?action=/ }
  post '/storage/', to: 'storage#create', as: 'new_storage'

  put '/storage/:id', to: 'storage#update'
  #put '/storage/' is undefined in GFD-P-R.185

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
  get '/mixin/os_tpl/:term/', to: 'os_tpl#show', as: 'os_tpl'
  get '/mixin/os_tpl/', to: 'os_tpl#index', as: 'os_tpls'

  post '/mixin/os_tpl/:term/', to: 'os_tpl#trigger', constraints: { query_string: /^\?action=/ }

  ####################################################
  ## Occi::Infrastructure::ResourceTpl
  ####################################################
  get '/mixin/resource_tpl/:term/', to: 'resource_tpl#show', as: 'resource_tpl'
  get '/mixin/resource_tpl/', to: 'resource_tpl#index', as: 'resource_tpls'

  post '/mixin/resource_tpl/:term/', to: 'resource_tpl#trigger', constraints: { query_string: /^\?action=/ }

  ####################################################
  ## Occi::Core::Mixin (user-defined mixins)
  ####################################################
  get '/mixin/*term/', to: 'mixin#index', as: 'mixin'

  post '/mixin/*term/', to: 'mixin#trigger', constraints: { query_string: /^\?action=/ }
  post '/mixin/*term/', to: 'mixin#assign', as: 'assign_mixin'

  put '/mixin/*term/', to: 'mixin#update', as: 'update_mixin'

  delete '/mixin/*term/', to: 'mixin#delete', as: 'unassign_mixin'

  ####################################################
  ## Default route
  ####################################################
  root 'model#index'
end
