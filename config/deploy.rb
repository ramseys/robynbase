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

# NOTE: deploy_via was removed in Capistrano 3.x - this setting is ignored
# The standard Git SCM strategy is used (server clones from repository directly)
# set :deploy_via, :copy

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

# EXPERIMENT: Temporarily allowing capistrano-rails to link public/assets to shared
# to observe what happens during asset precompilation
# Prevent capistrano-rails from automatically linking public/assets to shared
# The gem's default behavior (in assets.rake) adds public/assets to linked_dirs,
# which prevents fresh asset compilation on each deploy. We override that task here.
namespace :deploy do
  # COMMENTED OUT FOR EXPERIMENT: Allowing default asset linking behavior
  # task :set_linked_dirs do
  #   # Override the capistrano-rails gem task to prevent automatic asset linking
  #   # This ensures assets are compiled fresh on each deployment
  # end

  # Handle modern Rails 7+ asset bundling (jsbundling-rails + cssbundling-rails)
  namespace :assets do
    desc 'Run yarn install'
    task :yarn_install do
      on roles(:web) do
        within release_path do
          execute :yarn, 'install', '--frozen-lockfile'
        end
      end
    end

    desc 'Build JavaScript assets with esbuild'
    task :build_js do
      on roles(:web) do
        within release_path do
          execute :yarn, 'build'
        end
      end
    end

    desc 'Build CSS assets with sass'
    task :build_css do
      on roles(:web) do
        within release_path do
          execute :yarn, 'build:css'
        end
      end
    end
  end

  # after the deploy, we need to get passenger to restart itself
  desc "Restart passenger"
  task :restart_passenger do
    on roles(:app) do
      execute "touch #{ current_path }/tmp/restart.txt"
    end
  end

  # Hook to concrete task instead of phase for reliability
  # deploy:symlink:release runs at the moment "current" symlink is updated to new release
  after 'deploy:symlink:release', 'deploy:restart_passenger'

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end
end

# Hook the modern asset building tasks to run before assets:precompile
before 'deploy:assets:precompile', 'deploy:assets:yarn_install'
before 'deploy:assets:precompile', 'deploy:assets:build_js'
before 'deploy:assets:precompile', 'deploy:assets:build_css'
