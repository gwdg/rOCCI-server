require 'yard'

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', 'app/**/*.rb', 'README.md', 'LICENSE']
  # t.options = []
end