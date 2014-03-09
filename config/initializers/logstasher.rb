# Configure Logstasher
if LogStasher.enabled
  LogStasher.add_custom_fields do |fields|
    # This block is run in application_controller context,
    # so you have access to all controller methods
    fields[:user] = current_user && (current_user.identity || 'unknown')
    fields[:authn_strategy] = current_user && (current_user.auth!.type || 'unknown')
    fields[:uuid] = request.uuid || 'unknown'
  end
end
