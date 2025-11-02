# Infinite Pagination Implementation Session

## Overview
This session implemented infinite scroll functionality across the application's main data tables (songs, venues, gigs, compositions) and addressed related issues with Turbo navigation and JavaScript loading.

## Key Changes Made

### 1. Infinite Scroll Implementation

#### Core JavaScript Controller
- **Created**: `app/javascript/controllers/infinite_scroll_controller.js`
  - Detects scroll position and triggers loading when near bottom of page
  - Fetches next page via AJAX and appends rows to existing table
  - Manages pagination state (current page, has next page, etc.)
  - Handles search parameters, sort state, and query parameters
  - Includes loading indicators and error handling

#### Shared Controller Concern
- **Created**: `app/controllers/concerns/infinite_scroll_concern.rb`
  - Extracted common infinite scroll logic from individual controllers
  - Handles both regular searches and quick queries
  - Configurable via `infinite_scroll_config` method in each controller
  - Supports additional locals for controller-specific partial variables

### 2. Per-Table Implementation

#### Songs Table
- **Controller**: Added `include InfiniteScrollConcern` to `SongsController`
- **Route**: Added `get :infinite_scroll` to songs routes
- **View**: Updated `_song_list.html.erb` with infinite scroll data attributes
- **Partial**: Created `_song_rows.html.erb` for AJAX row rendering
- **Config**: Added `infinite_scroll_config` with songs-specific settings
- **Special handling**: Added `show_lyrics` parameter via `additional_locals`

#### Venues Table  
- **Controller**: Added `include InfiniteScrollConcern` to `VenuesController`
- **Route**: Added `get :infinite_scroll` to venues routes
- **View**: Updated `_venue_list.html.erb` with infinite scroll data attributes
- **Partial**: Created `_venue_rows.html.erb` for AJAX row rendering
- **Config**: Added `infinite_scroll_config` with venues-specific settings

#### Gigs Table
- **Controller**: Added `include InfiniteScrollConcern` to `GigsController` 
- **Route**: Added `get :infinite_scroll` to gigs routes
- **View**: Updated `_gig_list.html.erb` with infinite scroll data attributes
- **Partial**: Created `_gig_rows.html.erb` for AJAX row rendering
- **Config**: Added `infinite_scroll_config` with gigs-specific settings

#### Compositions/Releases Table
- **Controller**: Added `include InfiniteScrollConcern` to `CompositionsController`
- **Route**: Added `get :infinite_scroll` to compositions routes  
- **View**: Updated `_release_list.html.erb` with conditional infinite scroll
- **Partial**: Created `_composition_rows.html.erb` for AJAX row rendering
- **Config**: Added `infinite_scroll_config` with compositions-specific settings
- **Special feature**: Conditional behavior - infinite scroll disabled when `use_paging` is true

### 3. Parameter Standardization

#### Search Parameter Consistency
Standardized all search value parameters to use `search_value` instead of table-specific names:
- **Songs**: `song_search_value` → `search_value`
- **Venues**: `venue_search_value` → `search_value` 
- **Gigs**: `gig_search_value` → `search_value`
- **Compositions**: `album_search_value` → `search_value`

Updated controllers, views, and form fields to use consistent naming.

#### Enhanced Parameter Handling
- **Search parameters**: `search_type`, `search_value`
- **Sort parameters**: `sort`, `direction` 
- **Query parameters**: `query_type`, `query_id`, `query_attribute`
- **Pagination**: `page`, managed automatically

### 4. Sort State Management

#### Default Sort Headers Issue
Fixed issue where default sort order wasn't reflected in table headers on initial page load.

**Solution**: Enhanced `apply_sorting_and_pagination` method in `Paginated` concern to accept `default_sort_params`:
```ruby
apply_sorting_and_pagination(collection, 
  default_sort: "SONG.Song asc",
  default_sort_params: { sort: 'name', direction: 'asc' }
)
```

#### Sort State Preservation
Infinite scroll now maintains sort order across page loads by passing sort parameters in AJAX requests.

### 5. Quick Query Support

#### Enhanced Query Handling
Extended infinite scroll to support both regular searches and quick queries:
- **Regular searches**: Use `Model.search_by()` 
- **Quick queries**: Use `Model.quick_query()` based on `query_type` parameter

#### Configuration
Controllers determine query type via `infinite_scroll_config`:
```ruby
data-infinite-scroll-query-type-value="<%= params[:query_id].present? ? 'quick_query' : 'search' %>"
```

### 6. Code Organization Improvements

#### DRY Principle Implementation
- **Before**: Each controller had nearly identical `infinite_scroll` methods (~30 lines each)
- **After**: Shared logic in `InfiniteScrollConcern`, controllers provide minimal configuration

#### Reorder Logic Optimization  
Moved `collection.reorder('')` logic into `apply_sorting` methods to eliminate redundant calls.

### 7. Turbo Navigation Issues

#### Problem Identified
- `DOMContentLoaded` events not firing reliably with Turbo navigation
- JavaScript only executed on full page refreshes, not on navigation

#### Map Controller Fix
**Problem**: `loadVenueOmniMap` function undefined on Turbo navigation due to race condition between script loading and execution.

**Solution**: Converted to Stimulus controller
- **Created**: `app/javascript/controllers/map_controller.js`
- **Updated**: `app/views/map/index.html.erb` to use `data-controller="map"`
- **Benefits**: No race conditions, works with Turbo navigation, automatic cleanup

### 8. Implementation Details

#### Stimulus Values Used
```javascript
static values = {
  url: String,                    // Infinite scroll endpoint  
  currentPage: Number,            // Current page number
  hasNextPage: Boolean,          // Whether more pages exist
  currentSort: String,           // Active sort column
  currentDirection: String,      // Sort direction (asc/desc)
  searchType: String,            // Search field type
  searchValue: String,           // Search query text
  queryType: String,             // 'search' or 'quick_query'
  queryId: String,               // Quick query identifier
  queryAttribute: String         // Quick query attribute
}
```

#### View Integration Pattern
```erb
<table data-controller="row-navigation <%= 'infinite-scroll' unless use_paging %>"
       data-infinite-scroll-url-value="/songs/infinite_scroll"
       data-infinite-scroll-current-page-value="<%= @pagy.page %>"
       data-infinite-scroll-has-next-page-value="<%= @pagy.next.present? %>"
       <!-- ... other data attributes ... -->>
  <tbody data-infinite-scroll-target="tbody">
    <!-- table rows -->
  </tbody>
</table>
```

#### Controller Configuration Pattern
```ruby
def infinite_scroll_config
  {
    model: Song,
    records_name: :songs,
    partial: 'song_rows', 
    default_sort: "SONG.Song asc",
    default_sort_params: { sort: 'name', direction: 'asc' },
    additional_locals: { show_lyrics: (params[:search_type] == "lyrics") }
  }
end
```

## Files Created
- `app/javascript/controllers/infinite_scroll_controller.js`
- `app/controllers/concerns/infinite_scroll_concern.rb`
- `app/javascript/controllers/map_controller.js`
- `app/views/songs/_song_rows.html.erb`
- `app/views/venues/_venue_rows.html.erb` 
- `app/views/gigs/_gig_rows.html.erb`
- `app/views/compositions/_composition_rows.html.erb`

## Files Modified
- All main controller files (songs, venues, gigs, compositions)
- All main table view files (`_*_list.html.erb`)
- All search form files (`index.html.erb`) 
- `config/routes.rb` (added infinite scroll routes)
- `app/javascript/controllers/index.js` (registered new controllers)
- `app/controllers/concerns/paginated.rb` (enhanced sorting)
- `app/views/map/index.html.erb` (converted to Stimulus)

## Benefits Achieved
1. **Improved UX**: Seamless loading without pagination clicks
2. **Consistent behavior**: All tables work the same way
3. **Maintainable code**: Shared logic, minimal duplication
4. **Robust navigation**: Works with both full page loads and Turbo
5. **Flexible configuration**: Easy to customize per table
6. **Preserved functionality**: All existing features (search, sort, quick queries) maintained

### 9. Screen Filling Enhancement

#### Problem Identified
When the browser window is tall enough and the initial page load contains fewer records than needed to create a vertical scrollbar, infinite scroll events never fire because there's no scrolling possible. Users only see a subset of available data.

#### Solution Implemented
**Auto-fill Screen Logic**: Enhanced `infinite_scroll_controller.js` to automatically load enough data to fill the screen on initial load and after each AJAX request.

**Key Changes**:
- **Added `ensureScreenFilled()` method**: Calculates if more data is needed to fill the viewport
- **Added `calculateAvailableHeight()` method**: Uses `getBoundingClientRect()` to measure actual available space for the table (accounts for navbar, search forms, headers, etc.)
- **Added `getEstimatedRowHeight()` method**: Measures actual row height or falls back to 60px
- **Modified `connect()` method**: Calls `ensureScreenFilled()` after initial load
- **Modified `loadNextPage()` method**: Calls `ensureScreenFilled()` after loading new data

**Logic Flow**:
1. Calculate viewport height minus table's distance from top minus bottom buffer
2. Estimate rows needed based on actual row height
3. If current rows < needed rows, automatically load next page
4. Repeat until screen is filled or no more data available

**Benefits**:
- Works across all index pages (gigs, songs, venues, releases) without modification
- Adapts to different screen sizes and browser window heights
- Accounts for variable UI elements (expanded search forms, different headers)
- No backend changes required - uses existing pagination system

#### Implementation Details
```javascript
ensureScreenFilled() {
  const availableHeight = this.calculateAvailableHeight()
  const estimatedRowHeight = this.getEstimatedRowHeight()
  const neededRows = Math.ceil(availableHeight / estimatedRowHeight) + 3 // +3 buffer
  const currentRows = this.tbodyTarget.children.length

  if (currentRows < neededRows && this.hasNextPageValue) {
    this.loadNextPage() // Will recursively call ensureScreenFilled()
  }
}

calculateAvailableHeight() {
  const viewportHeight = window.innerHeight
  const tableElement = this.element.closest('table')
  const tableRect = tableElement.getBoundingClientRect()
  return Math.max(viewportHeight - tableRect.top - 50, 200) // 50px bottom buffer
}
```

## Future Considerations
- Could extend to other tables (tracks, users, etc.)
- Could add configurable page sizes based on screen dimensions
- Could add infinite scroll disable/enable toggle
- Consider performance optimizations for very large datasets
- Could implement server-side dynamic page sizing based on viewport height