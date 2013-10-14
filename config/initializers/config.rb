# Load general configuration from config.yml
ROCCI_SERVER_CONFIG = YAML.load_file(Rails.root.join('config', 'config.yml'))[Rails.env]