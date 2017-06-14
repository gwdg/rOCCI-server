# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
Mime::Type.register 'text/occi', :occi_headers
Mime::Type.register 'text/uri-list', :uri_list

Mime::Type.unregister :json
Mime::Type.register(
  'application/json',
  :json,
  %w[ text/x-json application/jsonrequest application/occi+json ],
  %w[occi_json]
)

# This is needed for routing purposes later on
LEGACY_FORMATS = %i[text occi_headers uri_list].freeze
