require 'bundler/capistrano'

# Warning
Capistrano::CLI.ui.say <<"EOF";

<%= color('IMPORTANT:', RED) %>
   * Capistrano will NOT make any privileged changes on your server!
   * You need Ruby 1.9.3+ already installed on your server!
   * You need the bundler gem installed on your server!
   * The server-side user has to be able to write into /opt/rOCCI-server!

     mkdir /opt/rOCCI-server
     chown rocci:rocci /opt/rOCCI-server

   * Apache2 has to be installed and properly configured!
   * Apache2 VirtualHost must use /opt/rOCCI-server/current/public as DocumentRoot and Directory!
   * Cron has to be installed and the use of crontab allowed for the selected server-side user!

EOF

# Info
Capistrano::CLI.ui.say <<"EOF";
<%= color('ENV defaults:', GREEN) %>
   CAP_ROCCI_SERVER_USER = #{ENV['CAP_ROCCI_SERVER_USER']}
   CAP_ROCCI_APP_SERVER = #{ENV['CAP_ROCCI_APP_SERVER']}

EOF

set :application, 'rOCCI-server'
set :repository,  'https://github.com/EGI-FCTF/rOCCI-server.git'
ssh_options[:forward_agent] = false

set :use_sudo, false
set :deploy_to, "/opt/#{application}"
set :rails_env, 'production'
set :keep_releases, 2
set :ssh_options,  auth_methods: %w(gssapi-with-mic publickey) 
set :bundle_without,  [:development, :test]

default_run_options[:shell] = '/bin/bash --login'
default_run_options[:pty] = true

# Remote servers
if ENV['CAP_ROCCI_SERVER_USER'] && !ENV['CAP_ROCCI_SERVER_USER'].empty?
  set :user, ENV['CAP_ROCCI_SERVER_USER']
else
  set(:user) { Capistrano::CLI.ui.ask('What is the name of rOCCI-server\'s server-side user account?  ') { |q|; q.default = 'rocci'; } }
end

if ENV['CAP_ROCCI_APP_SERVER'] && !ENV['CAP_ROCCI_APP_SERVER'].empty?
  role :app, ENV['CAP_ROCCI_APP_SERVER']
  role :web, ENV['CAP_ROCCI_APP_SERVER']
  role :db, ENV['CAP_ROCCI_APP_SERVER']
else
  all_server = Capistrano::CLI.ui.ask('Where is your APP server running?  ') { |q|; q.default = 'localhost'; }

  role :app, all_server
  role :web, all_server
  role :db, all_server
end

# Cron
set :whenever_command, 'bundle exec whenever'
set :whenever_environment, defer { rails_env }
set :whenever_roles, [:app]
require 'whenever/capistrano'

# Tasks to run before & after deployment
before 'deploy', 'deploy:setup'
after 'deploy:restart', 'deploy:cleanup'

namespace :deploy do
  task :start, roles: :app do
    run "/bin/true"
  end

  task :stop, roles: :app do
    run "/bin/true"
  end

  task :restart, roles: :app, except: { no_release: true } do
    run "#{try_sudo} touch #{File.join(current_path, 'tmp', 'restart.txt')}"
  end
end

namespace :remote_debug do
  desc 'Tail production log files'
  task :tail_logs, roles: :app do
    run "tail -f #{shared_path}/log/production.log" do |channel, stream, data|
      puts  # for an extra line break before the host name
      puts "#{channel[:host]}: #{data}"
      break if stream == :err
    end
  end

  desc 'Tail cron log files'
  task :tail_cronlogs, roles: :app do
    run "tail -f #{shared_path}/log/cronjobs.log" do |channel, stream, data|
      puts  # for an extra line break before the host name
      puts "#{channel[:host]}: #{data}"
      break if stream == :err
    end
  end

  desc 'Open production log files in VIM'
  task :vim_logs, roles: :app do
    tmp = ''
    logs = Hash.new { |h, k| h[k] = '' }

    run "tail -n 500 #{shared_path}/log/production.log" do |channel, stream, data|
      logs[channel[:host]] << data
      break if stream == :err
    end

    logs.each do |host, log|
      tmp << "--- #{host} ---\n\n"
      tmp << "#{log}\n"
    end

    exec "echo '#{tmp}' | vim -"
  end
end
