ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/mock'

# Auditing is disabled for the suite so tests that touch tracked models don't write
# version rows. Opt in per test with `with_versioning`. See
# docs/plans/auditing/3-record-change-tracking-plan.md.
PaperTrail.enabled = false

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  # Enable PaperTrail for the duration of the block.
  #
  # Note: under transactional fixtures every version created within a single test
  # shares one transaction_id. Each test that asserts grouping therefore performs
  # exactly ONE versioned logical transaction (do non-versioned setup outside the
  # block). Tests that need multiple distinct transactions would require truncation
  # (see the testing note in the plan).
  def with_versioning
    was_enabled = PaperTrail.enabled?
    was_request_enabled = PaperTrail.request.enabled?
    PaperTrail.enabled = true
    PaperTrail.request.enabled = true
    yield
  ensure
    PaperTrail.enabled = was_enabled
    PaperTrail.request.enabled = was_request_enabled
  end
end
