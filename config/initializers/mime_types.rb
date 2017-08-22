# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
Mime::Type.register 'text/plain', :text, [], %w[txt]
Mime::Type.register 'text/occi', :headers
Mime::Type.register 'text/uri-list', :uri_list

Mime::Type.unregister :json # we have to get rid of the old definition first
Mime::Type.register 'application/json', :json, %w[text/x-json application/jsonrequest application/occi+json]
