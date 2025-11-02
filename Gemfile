source 'https://rubygems.org'

gem 'rails', '~> 7.2.0'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# gem 'sqlite3'
gem 'mysql2', '0.5.6'

# needed because rails 7 doesn't use it by default anymore
gem "sprockets-rails"

# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Authorization
gem 'cancancan', '~> 3.5.0'

# Pagination
gem 'pagy', '~> 9.0'

# Turbo and Stimulus for modern Rails
gem 'turbo-rails', '~> 2.0'
gem 'stimulus-rails', '~> 1.3'

gem 'listen'
gem 'bootsnap'
gem 'sass-rails'

# supports active storage image variants
gem 'mini_magick'
gem 'image_processing'

# Gems used only for assets and not required
# in production environments by default.
#group :assets do
#  gem 'sass-rails',   '~> 3.2.3'
#  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

#  gem 'uglifier', '>= 1.0.3'
#end

gem 'uglifier', '>= 1.3.0'

# used to handle data (as opposed to schema) migrations
gem 'data_migrate'

gem 'jquery-rails'

gem "jsbundling-rails", "~> 1.1"

gem "cssbundling-rails", "~> 1.1"

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

group :development do
  gem 'capistrano', '3.19.2', require: false
  gem "puma"
  gem 'capistrano-rails', '1.7.0', require: false
  gem 'rvm1-capistrano3', require: false
  gem 'web-console'
  gem 'pry-rails'
  gem 'pry-byebug'
end
