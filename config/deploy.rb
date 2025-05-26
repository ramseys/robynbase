# config valid only for current version of Capistrano
lock '3.19.2'

set :application, 'robynbase'

# github repo url
set :repo_url, 'https://github.com/ramseys/robynbase.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# where on the server we're deploying to
set :deploy_to, '/var/www/robynbase'

# Pull app out of the master branch on github
set :branch, "master"

# User on the server-side under which deployments should be handled
set :user, "ramseys"

# don't let the deployer use sudo
set :use_sudo, false

set :rails_env, "production"

# download the repository to the local machine, then upload to server
set :deploy_via, :copy

# use agent forwarding
set :ssh_options, { :forward_agent => true }

# keep some releases around on the server
set :keep_releases, 10

# make sure password prompts and such show up in the terminal
set :pty, true

# had to do this because i don't have any indication in the home directory
# of which version of ruby rvm is on
set :rvm1_ruby_version, 'ruby-3.4.4'

# this is used by the built-in 'deploy:symlink:linked_files'. links up the
# shared database.yml file to the latest release
#
# link to the master decryption key in the shared config area
set :linked_files, %w{config/database.yml config/master.key}

# this is used by the built-in 'deploy:symlink:linked_dirs'. links up the
# shared two directories to the latest release: active storage files, and album art
set :linked_dirs, %w{public/images/album-art active-storage-files}

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml')

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('bin', 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }


namespace :deploy do

  # after the deploy, we need to get passenger to restart itself
  desc "Restart passenger"
  task :restart_passenger do
    on roles(:app) do
      execute "touch #{ current_path }/tmp/restart.txt"
    end
  end

  after 'deploy:finished', 'deploy:restart_passenger'

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
