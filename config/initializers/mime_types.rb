# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone
Mime::Type.register 'text/occi', :occi_header
Mime::Type.register 'application/occi+json', :occi_json
Mime::Type.register 'application/occi+xml', :occi_xml
Mime::Type.register 'text/uri-list', :uri_list
