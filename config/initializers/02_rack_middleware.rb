# Load extensions from Rails.root/lib/rack
Dir[Rails.root.join('lib', 'rack', '*.rb')].each { |file| require file.gsub('.rb', '') }
