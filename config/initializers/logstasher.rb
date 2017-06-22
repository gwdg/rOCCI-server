# Configure Logstasher
if LogStasher.enabled
  LogStasher.add_custom_fields do |fields|
    # This block is run in application_controller context,
    # so you have access to all controller methods
    fields[:user] = current_user
    fields[:authn_strategy] = 'token'
    fields[:uuid] = request.uuid
    fields[:ip] = request.remote_ip
    fields[:env] = Rails.env
  end
end
