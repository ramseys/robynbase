# SimpleCov must be loaded before application code
require 'simplecov'

SimpleCov.start 'rails' do
  add_filter '/test/'
  add_filter '/config/'
  add_filter '/vendor/'

  add_group 'Models', 'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Services', 'app/services'
  add_group 'Helpers', 'app/helpers'
  add_group 'Modules', 'app/modules'

  minimum_coverage 75  # Start with 75%, increase as we add tests
  minimum_coverage_by_file 60
end

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'database_cleaner/active_record'

# Configure DatabaseCleaner - use truncation for reliability
DatabaseCleaner.strategy = :truncation

class ActiveSupport::TestCase
  # Disable fixtures (we'll use FactoryBot instead)
  self.use_transactional_tests = false

  # DatabaseCleaner setup - clean before AND after each test
  setup do
    DatabaseCleaner.clean
  end

  teardown do
    DatabaseCleaner.clean
  end

  # FactoryBot shorthand methods
  include FactoryBot::Syntax::Methods
end

# Shoulda Matchers configuration
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end
