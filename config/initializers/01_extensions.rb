# Load extensions from Rails.root/lib/ext
Dir[Rails.root.join('lib', 'ext', '*.rb')].each { |file| require file.gsub('.rb', '') }
