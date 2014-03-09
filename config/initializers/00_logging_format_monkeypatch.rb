# Monkeypatch Rails' logger to get readable logs
class ActiveSupport::Logger::SimpleFormatter
  SEVERITY_TO_TAG_MAP     = { 'DEBUG' => 'meh', 'INFO' => 'fyi', 'WARN' => 'hmm', 'ERROR' => 'wat', 'FATAL' => 'omg', 'UNKNOWN' => '???' }
  SEVERITY_TO_COLOR_MAP   = { 'DEBUG' => '0;37', 'INFO' => '32', 'WARN' => '33', 'ERROR' => '31', 'FATAL' => '31', 'UNKNOWN' => '37' }
  USE_HUMOROUS_SEVERITIES = Rails.env.development?
  USE_COLORS              = Rails.env.development?

  def call(severity, time, progname, msg)
    return if msg.strip.blank?

    if USE_HUMOROUS_SEVERITIES
      formatted_severity = sprintf('%-3s', SEVERITY_TO_TAG_MAP[severity])
    else
      formatted_severity = sprintf('%-5s', severity)
    end

    formatted_time = time.strftime('%Y-%m-%d %H:%M:%S.') << time.usec.to_s[0..2].rjust(3)

    if USE_COLORS
      color = SEVERITY_TO_COLOR_MAP[severity]
      "\033[0;37m#{formatted_time}\033[0m [ \033[#{color}m#{formatted_severity}\033[0m ] #{msg.strip} (pid:#{Process.pid})\n"
    else
      "#{formatted_time} [ #{formatted_severity} ] #{msg.strip} (pid:#{Process.pid})\n"
    end
  end
end
