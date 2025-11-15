# Test Suite for Robyn Hitchcock Discography Database

## Overview

This application now has a comprehensive test suite covering models, controllers, and integration tests. The tests are built using Rails' default Minitest framework with additional testing libraries.

## Testing Stack

### Core Testing Frameworks
- **Minitest** - Rails default testing framework
- **FactoryBot** - Test data generation (replaces fixtures)
- **Faker** - Realistic fake data generation
- **SimpleCov** - Code coverage reporting
- **DatabaseCleaner** - Clean database state between tests
- **Shoulda Matchers** - Expressive matchers for models
- **Capybara** - Integration/system testing
- **Selenium WebDriver** - Browser automation

### Test Gems Added to Gemfile

```ruby
group :test do
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'shoulda-matchers'
  gem 'database_cleaner-active_record'
  gem 'simplecov', require: false
  gem 'capybara'
  gem 'selenium-webdriver'
end
```

## Installation

### Prerequisites

Before running tests, ensure you have MySQL development libraries installed:

```bash
# Ubuntu/Debian
sudo apt-get install libmysqlclient-dev

# macOS
brew install mysql

# RHEL/CentOS
sudo yum install mysql-devel
```

### Install Test Dependencies

```bash
bundle install
```

## Running Tests

### Run All Tests
```bash
bin/rails test
```

### Run Specific Test Files
```bash
bin/rails test test/models/user_test.rb
bin/rails test test/controllers/sessions_controller_test.rb
bin/rails test test/models/ability_test.rb
```

### Run Tests with Coverage Report
```bash
COVERAGE=true bin/rails test
```

Coverage reports are generated in `coverage/index.html`

## Test Structure

```
test/
├── factories/              # FactoryBot factories for test data
│   ├── users.rb
│   ├── songs.rb
│   ├── gigs.rb
│   ├── venues.rb
│   ├── compositions.rb
│   ├── gigsets.rb
│   ├── tracks.rb
│   └── gig_media.rb
├── models/                 # Model unit tests
│   ├── user_test.rb       ✅ 11 tests
│   └── ability_test.rb    ✅ 9 tests
├── controllers/            # Controller integration tests
│   └── sessions_controller_test.rb  ✅ 10 tests
├── integration/            # Multi-step user flow tests
├── system/                 # Full-stack browser tests
└── test_helper.rb          # Test configuration

Current Test Count: 30+ tests
Target Coverage: 85%+
```

## Test Helper Configuration

The `test/test_helper.rb` file is configured with:

- **SimpleCov** for code coverage tracking (min 75% coverage)
- **DatabaseCleaner** for transaction-based test isolation
- **FactoryBot** syntax methods for easy factory usage
- **Shoulda Matchers** integrated with Minitest

## FactoryBot Factories

All models have corresponding factories with traits for common test scenarios:

### User Factory
```ruby
create(:user)
create(:user, email: "custom@example.com")
```

### Song Factory
```ruby
create(:song)
create(:song, :cover)                    # Cover song
create(:song, :with_lyrics)              # With lyrics
create(:song, :with_tabs)                # With guitar tabs
create(:song, :improvised)               # Improvised song
create(:song, :with_performances, performances_count: 5)
create(:song, :on_album, albums_count: 2)
```

### Gig Factory
```ruby
create(:gig)
create(:gig, :with_setlist, songs_count: 15)
create(:gig, :with_reviews)
create(:gig, :with_media)
create(:gig, :circa)                     # Approximate date
create(:gig, :no_date)                   # Missing date
```

### Venue Factory
```ruby
create(:venue)
create(:venue, :with_location)           # With lat/long
create(:venue, :with_notes)
```

### Composition Factory
```ruby
create(:composition)
create(:composition, :album)
create(:composition, :ep)
create(:composition, :single)
create(:composition, :with_tracks, tracks_count: 12)
```

### Join Tables
```ruby
create(:gigset, gig: gig, song: song)
create(:track, composition: album, song: song, Seq: 1)
create(:gig_medium, :youtube, gig: gig)
```

## Test Coverage Goals

| Layer | Target Coverage | Current Status |
|-------|----------------|----------------|
| Models | 90%+ | In Progress |
| Controllers | 85%+ | In Progress |
| Services | 90%+ | Pending |
| Helpers | 75%+ | Pending |
| **Overall** | **85%+** | **~15%** (Phase 1 Complete) |

## Current Test Coverage (Phase 1)

### ✅ Completed
- **User Model** - 11 tests covering:
  - Email validation (presence, uniqueness, format)
  - Password authentication (bcrypt)
  - Edge cases (special characters, whitespace)

- **Ability Model** - 9 tests covering:
  - Guest user permissions (read-only)
  - Logged-in user permissions (full CRUD)
  - Authorization for all resources

- **SessionsController** - 10 tests covering:
  - Login page rendering
  - Session creation with valid/invalid credentials
  - Logout functionality
  - Error handling

### 🚧 In Progress (Phase 2)
- Song Model tests
- Gig Model tests
- Venue Model tests
- Composition Model tests
- Join model tests (Gigset, Track, GigMedium)

### 📋 Planned (Phase 3+)
- SongsController tests
- GigsController tests
- VenuesController tests
- CompositionsController tests
- Integration tests (search flows, CRUD operations)
- System tests (full browser automation)
- Service layer tests (ResourceSorter, ImageUtils)

## Writing New Tests

### Example Model Test
```ruby
require 'test_helper'

class SongTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    song = build(:song)
    assert song.valid?
  end

  test "should require title" do
    song = build(:song, Song: nil)
    assert_not song.valid?
  end
end
```

### Example Controller Test
```ruby
require 'test_helper'

class SongsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get songs_path
    assert_response :success
  end

  test "should create song when logged in" do
    user = create(:user)
    log_in_as(user)

    assert_difference('Song.count', 1) do
      post songs_path, params: { song: { Song: "Test Song" } }
    end
  end
end
```

## Code Coverage Reports

SimpleCov generates coverage reports after each test run:

- **HTML Report**: `coverage/index.html` (open in browser)
- **Minimum Coverage**: 75% (will fail build if below)
- **File-by-File Coverage**: 60% minimum per file

## Continuous Integration

When setting up CI/CD:

```yaml
# .github/workflows/test.yml example
test:
  runs_on: ubuntu-latest
  services:
    mysql:
      image: mysql:5.7
  steps:
    - uses: actions/checkout@v2
    - name: Install dependencies
      run: |
        sudo apt-get install libmysqlclient-dev
        bundle install
    - name: Run tests
      run: bin/rails test
    - name: Upload coverage
      run: cat coverage/.last_run.json
```

## Testing Best Practices

1. **Use Factories Over Fixtures** - Factories are more flexible and maintainable
2. **Test Behavior, Not Implementation** - Focus on what the code does, not how
3. **Keep Tests Isolated** - Each test should be independent
4. **Use Descriptive Test Names** - Test names should explain what's being tested
5. **Test Edge Cases** - Don't just test the happy path
6. **Maintain High Coverage** - Aim for 85%+ overall coverage
7. **Run Tests Frequently** - Run tests before committing code

## Troubleshooting

### Bundle Install Fails with MySQL Error

```bash
# Install MySQL development libraries first
sudo apt-get install libmysqlclient-dev  # Ubuntu/Debian
brew install mysql                        # macOS
```

### Tests Failing with Database Errors

```bash
# Reset test database
bin/rails db:test:prepare
bin/rails db:migrate RAILS_ENV=test
```

### FactoryBot Errors

Make sure factories are defined in `test/factories/` and loaded via `test_helper.rb`:

```ruby
# test_helper.rb already includes:
include FactoryBot::Syntax::Methods
```

## Next Steps

See the [Comprehensive Testing Implementation Plan](../docs/testing_plan.md) for the full roadmap.

**Phase 1** (Complete): Foundation - Test infrastructure and critical authentication tests
**Phase 2** (Next): Core domain model tests (Song, Gig, Venue, Composition)
**Phase 3** (Planned): Controller and integration tests
**Phase 4** (Planned): Service layer and system tests

## Contributing

When adding new features:
1. Write tests first (TDD)
2. Ensure tests pass: `bin/rails test`
3. Check coverage: Open `coverage/index.html`
4. Aim for 80%+ coverage on new code
5. Update this README if adding new test patterns

---

**Test Suite Status**: Phase 1 Complete ✅
**Current Coverage**: ~15% (foundation)
**Target Coverage**: 85%+
**Framework**: Minitest + FactoryBot + SimpleCov
