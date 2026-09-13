ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/mock'

# Auditing is disabled for the suite so tests that touch tracked models don't write
# version rows. Opt in per test with `with_versioning`. See
# docs/plans/auditing/3-record-change-tracking-plan.md.
PaperTrail.enabled = false

# Shared assertions for the search navigation the four category controllers put in
# their show-page header (see SearchNavigable and shared/_show_header), so the four
# functional tests check it the same way.
module SearchNavAssertions

  # The search context hanging off each row link of a rendered listing, in row order
  def search_backs_in_rows
    @response.body.scan(/href="[^"]*\?search_back=([^"]*)" class="row-link"/).flatten.map { |value| CGI.unescape(value) }
  end

  # The rendered show-page header block, delimited by balancing its <div> tags so it
  # doesn't depend on how the ERB happens to be indented
  def rendered_show_header
    body = @response.body
    start = body.index('<div class="show-header">')
    finish = nil

    if start
      depth = 0
      body[start..].scan(/<div\b|<\/div>/) do |tag|
        depth += (tag == "</div>" ? -1 : 1)
        if depth.zero?
          finish = start + Regexp.last_match.end(0)
          break
        end
      end
    end

    body[start...finish] if finish
  end

  # The search controls that sit on the title row
  def rendered_search_steps
    header = rendered_show_header.to_s
    from = header.index('<div class="show-header-steps">')

    header[from...(header.index('<div class="inpage-navigation">') || header.length)] if from
  end

  # { prev:, back:, next: } from a rendered show page, or nil when the page carries no
  # search context at all. prev/next are nil individually when that step is suppressed.
  def rendered_search_nav
    header = rendered_show_header.to_s
    control = ->(label) { header[/<a href="([^"]*)"[^>]*title="#{label}"/, 1]&.then { |h| CGI.unescapeHTML(h) } }
    back = control.call("Back to Search")

    { back: back, prev: control.call("Previous result"), next: control.call("Next result") } if back
  end

  # The in-page link line beneath the title (anchor links plus the admin Edit link)
  def rendered_header_links
    rendered_show_header.to_s[/<div class="inpage-navigation">.*?<\/div>/m]
  end

end

class ActionController::TestCase
  include SearchNavAssertions
end

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
