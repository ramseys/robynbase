# Model Layer Testing Plan

## Overview
This plan focuses exclusively on testing the model layer of the Robyn Hitchcock discography application. The goal is to achieve comprehensive model coverage before moving to controllers and integration tests.

## Domain Understanding

### Core Entities
1. **Song** - Individual songs written/performed by Robyn Hitchcock
2. **Gig** - Live performances with date, venue, and setlist
3. **Composition** (Album/Release) - Studio releases containing tracks
4. **Venue** - Performance locations with geographic data
5. **Track** - Songs on specific releases
6. **Gigset** - Songs performed at specific gigs (with order/notes)
7. **GigMedium** - Media links (YouTube, etc.) for gigs
8. **User** - Authentication for admin functions
9. **Musician** - Additional performers/collaborators
10. **Ability** - CanCanCan authorization rules

### Key Relationships
- Song ↔ Track ↔ Composition (songs appear on albums)
- Song ↔ Gigset ↔ Gig (songs performed at gigs)
- Gig → Venue (gigs happen at venues)
- Gig ↔ GigMedium (gigs have media links)

## Testing Strategy

### Phase 1: Core Models - Validations & Basic Behavior
**Goal**: Ensure basic model integrity and data validation
**Duration**: 2-3 days

#### 1.1 Song Model
- [ ] Validates presence of required fields (Song name)
- [ ] Handles article prefixes (A/An/The) via `parse_song_name`
- [ ] Properly stores and retrieves lyrics, comments, tabs
- [ ] `full_name` method combines prefix and song name
- [ ] Handles special characters in song names
- [ ] `performance_info` returns correct gig statistics
- [ ] Sanitizes text fields (Comments, Lyrics) on save

**Edge Cases**:
- Songs with very long titles (VARCHAR limits)
- Songs with special SQL characters
- Songs without lyrics/comments (nil handling)
- Improvised vs. written songs

#### 1.2 Gig Model
- [ ] Requires venue association
- [ ] Validates date presence/format
- [ ] Auto-populates GigYear from GigDate
- [ ] Handles circa dates (uncertain dates)
- [ ] `get_set` returns non-encore songs in order
- [ ] `get_set_encore` returns encore songs in order
- [ ] Formats reviews with line breaks
- [ ] Sanitizes text fields (Reviews, ShortNote)

**Edge Cases**:
- Gigs without definite dates (Circa flag)
- Gigs with nil dates
- Gigs with multiple setlists
- Very long guest lists or reviews

#### 1.3 Composition Model
- [ ] Validates presence of Title and Artist
- [ ] Associates with tracks in correct sequence
- [ ] `get_tracklist` returns non-bonus tracks
- [ ] `get_tracklist_bonus` returns bonus tracks
- [ ] Handles different release types (Album, Single, EP, etc.)
- [ ] Handles duplicate releases (multiple editions)

**Edge Cases**:
- Compilations with tracks from different eras
- Singles vs. Albums vs. EPs
- Bootlegs and fan releases
- Very long album titles or artist names

#### 1.4 Venue Model
- [ ] Validates name, city, country presence
- [ ] Stores geographic coordinates (optional)
- [ ] Formats notes with line breaks
- [ ] Associates with multiple gigs

**Edge Cases**:
- Venues with very long names (VARCHAR 48 limit)
- Venues with unicode characters (café, etc.)
- Venues without location data
- Venues with multiple addresses over time

### Phase 2: Association Tests
**Goal**: Verify relationships work correctly
**Duration**: 2 days

#### 2.1 Song Associations
- [ ] Song has_many gigsets
- [ ] Song has_many gigs through gigsets
- [ ] Song has_many tracks
- [ ] Song has_many compositions through tracks
- [ ] Deleting song doesn't cascade delete gigs/compositions

#### 2.2 Gig Associations
- [ ] Gig belongs_to venue (required)
- [ ] Gig has_many gigsets (ordered by Chrono)
- [ ] Gig has_many gigmedia (ordered by Chrono)
- [ ] Gig has_many songs through gigsets
- [ ] Deleting gig cascades to gigsets/gigmedia (dependent: :delete_all)
- [ ] Has_many_attached :images

#### 2.3 Composition Associations
- [ ] Composition has_many tracks (ordered by Seq)
- [ ] Composition has_many songs through tracks
- [ ] Composition has_many gigsets through songs
- [ ] Composition has_many gigs through gigsets (NEW in our fixes)
- [ ] Deleting composition cascades to tracks
- [ ] Has_many_attached :images

#### 2.4 Track & Gigset Join Tables
- [ ] Track belongs_to composition and song
- [ ] Track maintains sequence order
- [ ] Gigset belongs_to gig and song
- [ ] Gigset maintains chronological order
- [ ] Version notes stored correctly

### Phase 3: Search & Query Methods
**Goal**: Test complex queries and scopes
**Duration**: 2 days

#### 3.1 Song Search Methods
- [ ] `search_by(:title, "keyword")` finds songs by name
- [ ] `search_by(:lyrics, "keyword")` searches lyrics
- [ ] `search_by(:author, "name")` finds covers
- [ ] `search_by([:title, :lyrics], "keyword")` searches multiple fields
- [ ] `search_by` with nil returns all songs
- [ ] `prepare_query` adds gig_count correctly
- [ ] Handles SQL special characters safely

#### 3.2 Gig Search Methods
- [ ] `search_by(:venue, "name")` finds gigs by venue name
- [ ] `search_by(:gig_year, "2020")` finds gigs by year
- [ ] `search_by(:venue_city, "London")` finds by venue city
- [ ] `search_by` handles date criteria (date ranges)
- [ ] `search_by` filters by gig type
- [ ] Left joins with venue for city/state/country searches

#### 3.3 Venue Search Methods
- [ ] `search_by(:name, "keyword")` finds venues
- [ ] `search_by(:city, "keyword")` searches by city
- [ ] `search_by(:country, "keyword")` searches by country
- [ ] `prepare_query` adds gig_count correctly
- [ ] Orders results by name ascending

#### 3.4 Composition Search Methods
- [ ] `search_by(:title, "keyword")` finds by album title
- [ ] `search_by(:year, "1984")` finds by year
- [ ] `search_by(:label, "keyword")` finds by label
- [ ] Filters by release_types array
- [ ] De-duplicates multiple editions (keeps earliest COMPID)
- [ ] Orders by year ascending

### Phase 4: Quick Queries & Scopes
**Goal**: Test predefined query helpers
**Duration**: 1 day

#### 4.1 Song Quick Queries
- [ ] `quick_query(:not_written_by_robyn)` returns covers
- [ ] `quick_query(:never_released)` finds unreleased songs
- [ ] `quick_query(:never_released, :originals)` filters originals
- [ ] `quick_query(:never_released, :covers)` filters covers
- [ ] `quick_query(:has_guitar_tabs)` finds songs with tabs
- [ ] `quick_query(:has_lyrics)` finds songs with lyrics
- [ ] `quick_query(:improvised)` finds improvised songs
- [ ] `quick_query(:released_never_played_live)` finds studio-only songs

#### 4.2 Gig Quick Queries
- [ ] `quick_query(:with_setlists)` finds gigs with setlists
- [ ] `quick_query(:without_definite_dates)` finds circa gigs
- [ ] `quick_query(:with_reviews)` finds reviewed gigs
- [ ] `quick_query(:with_media)` finds gigs with media links
- [ ] `quick_query_gigs_on_this_day(month, day)` finds anniversary gigs

#### 4.3 Venue Quick Queries
- [ ] `quick_query(:with_notes)` finds venues with notes
- [ ] `quick_query(:with_location)` finds venues with coordinates

#### 4.4 Composition Quick Queries
- [ ] `quick_query(:other_bands)` finds non-Robyn releases

### Phase 5: Business Logic & Calculated Fields
**Goal**: Test derived data and complex methods
**Duration**: 1 day

#### 5.1 Song Business Logic
- [ ] `performance_info` calculates total performances
- [ ] `performance_info` finds first/last performance dates
- [ ] `performance_info` calculates duration between performances
- [ ] `parse_song_name` extracts articles correctly
- [ ] `full_name` reconstructs name with article

#### 5.2 Gig Business Logic
- [ ] GigYear auto-populates from GigDate on save
- [ ] Handles nil GigDate gracefully
- [ ] Circa flag indicates uncertain dates
- [ ] `get_reviews` formats with HTML line breaks

#### 5.3 Composition Business Logic
- [ ] RELEASE_TYPES constant defines ordering
- [ ] Handles Single flag for singles
- [ ] De-duplication keeps earliest edition by COMPID

#### 5.4 Venue Business Logic
- [ ] `get_notes` formats with HTML line breaks
- [ ] Latitude/longitude optional but validated when present

### Phase 6: Data Integrity & Edge Cases
**Goal**: Test error handling and boundary conditions
**Duration**: 1-2 days

#### 6.1 Validation Edge Cases
- [ ] Maximum length constraints (VARCHAR limits)
- [ ] Minimum required fields
- [ ] Unique constraints (if any)
- [ ] Foreign key constraints
- [ ] NULL handling for optional fields

#### 6.2 Character Encoding
- [ ] Unicode characters in names/lyrics
- [ ] Special SQL characters (' % _ etc.)
- [ ] HTML entities in text fields
- [ ] Emoji in modern data

#### 6.3 Date Handling
- [ ] Very old dates (1976 Soft Boys era)
- [ ] Future dates (upcoming gigs)
- [ ] Invalid dates
- [ ] Timezone handling
- [ ] Circa dates with nil values

#### 6.4 Aggregate Queries
- [ ] COUNT with GROUP BY returns correct counts
- [ ] Joins don't create duplicate records
- [ ] Order preserved through grouping
- [ ] NULL handling in aggregates

## Test Infrastructure

### Factory Setup
- [x] FactoryBot configured ✓
- [x] Base factories for all models ✓
- [ ] Traits for common scenarios (needs review)
- [ ] Sequences for unique values (needs review)
- [ ] Associations handled correctly (needs review)

### Test Data Strategy
- Use FactoryBot for test data generation
- Use Faker for realistic but safe data (with length limits)
- Avoid fixtures (already using FactoryBot)
- Create minimal data needed per test
- Use DatabaseCleaner with truncation strategy

### Coverage Goals
- **Target**: 85%+ model code coverage
- **Focus areas**: 
  - Public methods
  - Scopes and class methods
  - Associations
  - Validations
  - Business logic

## Implementation Approach

### Step 1: Review Existing Tests
- Examine current test/models/* files
- Identify what's already tested
- Note what's working vs. broken
- Keep working tests, fix or remove broken ones

### Step 2: Create Missing Test Files
- Ensure every model has a test file
- Use consistent naming (model_test.rb)
- Follow Minitest structure

### Step 3: Implement Phase by Phase
- Complete Phase 1 before moving to Phase 2
- Run tests frequently (after each test or small group)
- Fix failures immediately before continuing
- Commit working code after each phase

### Step 4: Refine Factories
- Ensure factories generate valid data
- Add traits for common test scenarios
- Handle VARCHAR limits and constraints
- Test factories themselves

### Step 5: Document & Clean Up
- Remove obsolete tests
- Add comments for complex test scenarios
- Update README with test running instructions
- Create test coverage report

## Success Criteria

### Must Have
- ✅ All core models have comprehensive tests
- ✅ All associations verified
- ✅ All public methods tested
- ✅ All search methods tested
- ✅ 85%+ code coverage on models
- ✅ Zero failing tests

### Nice to Have
- 90%+ code coverage
- Performance benchmarks for slow queries
- Tests for all quick queries
- Tests for text sanitization
- Tests for image attachments

## Timeline Estimate

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Phase 1: Core Models | 2-3 days | 3 days |
| Phase 2: Associations | 2 days | 5 days |
| Phase 3: Search Methods | 2 days | 7 days |
| Phase 4: Quick Queries | 1 day | 8 days |
| Phase 5: Business Logic | 1 day | 9 days |
| Phase 6: Edge Cases | 1-2 days | 10-11 days |
| **Total** | **10-11 days** | |

*Note: This is an estimate for implementation time. Actual time may vary based on complexity discovered during implementation.*

## Next Steps

1. **Review this plan** - Confirm approach and scope
2. **Create a new branch** - `testing/models-only`
3. **Review existing model tests** - See what's salvageable
4. **Start Phase 1** - Begin with Song model validations
5. **Iterate and refine** - Adjust plan based on discoveries

## Notes
- Focus on model layer only - no controller/view tests in this plan
- Integration tests will be a separate future plan
- This plan assumes using existing FactoryBot setup
- DatabaseCleaner already configured with truncation strategy
- SimpleCov already configured for coverage reporting
