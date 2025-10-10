# Server-Side Pagination Migration Plan

## Overview

This document outlines the plan to migrate from client-side DataTable pagination to server-side pagination with Rails Turbo for all data tables in the application (gigs, albums, songs, venues).

## Current State Summary

- **4 main tables**: Gigs, Songs, Venues, Albums/Releases
- **Full dataset loading**: All data loaded at once, paginated client-side via DataTables
- **No existing pagination gems**: Clean slate for implementation
- **No Turbo integration**: Currently using Rails UJS + jQuery
- **Rails 7.2**: Modern Rails version ready for Turbo

## Current DataTable Implementation

### Tables Using DataTable
- **Gigs Table** (`app/views/gigs/_gig_list.html.erb`)
- **Songs Table** (`app/views/songs/_song_list.html.erb`)
- **Venues Table** (`app/views/venues/_venue_list.html.erb`)
- **Albums/Releases Table** (`app/views/compositions/_release_list.html.erb`)

### Current Features
- Client-side sorting with cookie-based state persistence
- Global search (mostly disabled in favor of server-side search forms)
- Custom headers and styling
- Row click navigation
- Deferred rendering for performance

## Migration Plan

### Phase 1: Foundation Setup

1. **Add pagination gem**
   - Install Pagy (lightweight, fast alternative to Kaminari)
   - Add to Gemfile: `gem 'pagy'`
   - Configure in `config/initializers/pagy.rb`

2. **Add Turbo**
   - Install `@hotwired/turbo-rails` gem
   - Install `@hotwired/stimulus` for enhanced UX
   - Update `app/javascript/application.js`

3. **Update application layout**
   - Add Turbo configuration
   - Update CSP if needed for Turbo

### Phase 2: Server-Side Architecture

1. **Controller pagination**
   - Add Pagy to all list controllers:
     - `GigsController#index`
     - `SongsController#index`
     - `VenuesController#index`
     - `CompositionsController#index`
   - Include `Pagy::Backend` in ApplicationController

2. **Pagination helpers**
   - Create shared pagination concerns
   - Add `Pagy::Frontend` to ApplicationHelper
   - Create reusable pagination partial

3. **Search parameter handling**
   - Modify controllers to handle pagination + search parameters
   - Preserve search state across pagination
   - Update search forms to work with pagination

4. **URL structure**
   - Design pagination-friendly URLs: `/gigs?page=2&search=venue`
   - Maintain current search parameter structure
   - Ensure bookmarkable URLs

### Phase 3: Turbo Frame Integration

1. **Turbo Frame containers**
   - Wrap table content in `turbo_frame` tags
   - Create frame IDs: `gigs_table`, `songs_table`, etc.
   - Ensure proper frame targeting

2. **Pagination links**
   - Make pagination links target the table frame
   - Use `data-turbo-frame` attributes
   - Implement infinite scroll option

3. **Search forms**
   - Configure search forms to update table frames
   - Use `turbo_frame` targets on form submissions
   - Maintain current search UI/UX

4. **Sort links**
   - Convert column headers to server-side sort links
   - Preserve current sort state in URLs
   - Target table frames for sort updates

### Phase 4: Custom Table Component

1. **Replace DataTable JavaScript**
   - Remove DataTable initialization from `app/javascript/global.js`
   - Remove DataTable dependencies from package.json
   - Clean up DataTable-specific CSS

2. **Custom table styling**
   - Maintain current table styling without DataTable CSS
   - Keep existing classes: `main-search-list`, `row-border stripe table-hover`
   - Preserve action column styling and row hover effects

3. **Progressive enhancement**
   - Add Stimulus controllers for:
     - Row click navigation
     - Loading states during pagination
     - Enhanced UX (keyboard navigation, etc.)

4. **State preservation**
   - Implement sort/search state in URLs (replacing cookie-based approach)
   - Browser back/forward button support
   - Shareable URLs with current view state

### Phase 5: Migration Strategy

1. **Feature flag approach**
   - Add configuration to switch between old/new pagination
   - Environment variable: `USE_SERVER_SIDE_PAGINATION`
   - Allows testing and gradual rollout

2. **Table-by-table migration**
   - Start with Gigs table (most complex)
   - Then Songs, Venues, Albums/Releases
   - Learn and iterate with each table

3. **Fallback handling**
   - Graceful degradation for JavaScript-disabled users
   - Ensure full functionality without Turbo
   - Progressive enhancement approach

4. **Performance testing**
   - Compare load times before/after migration
   - Monitor database query performance
   - Test with large datasets
   - User experience testing

## Implementation Details

### Database Considerations
- Add database indexes for commonly sorted columns
- Optimize queries for pagination performance
- Consider view-level caching for expensive queries

### URL Structure Examples
```
# Current
/gigs

# New with pagination and search
/gigs?page=2&sort=date&direction=desc&search=venue&query=fillmore
```

### Turbo Frame Structure
```erb
<%= turbo_frame_tag "gigs_table" do %>
  <div class="table-container">
    <%= render 'gig_list' %>
    <%= render 'pagination' %>
  </div>
<% end %>
```

### Controller Changes
```ruby
class GigsController < ApplicationController
  include Pagy::Backend
  
  def index
    @pagy, @gigs = pagy(filtered_gigs, items: 20)
    # Handle Turbo Frame requests
  end
  
  private
  
  def filtered_gigs
    # Existing search logic + pagination
  end
end
```

## Benefits of Migration

1. **Performance**: Only load needed data, faster page loads
2. **Scalability**: Handle large datasets efficiently
3. **Modern Rails**: Leverage Turbo for better UX
4. **Maintainability**: Remove DataTable dependency
5. **SEO**: Better URL structure and server-rendered content
6. **Accessibility**: Improved screen reader support

## Recommendation: Jettison DataTable

**Yes, remove DataTable entirely** because:
- Current usage is minimal (just sorting/basic pagination)
- Server-side pagination eliminates need for client-side processing
- Turbo provides better Rails integration
- Smaller JavaScript bundle size
- More maintainable custom implementation

The custom implementation will be lighter, faster, and more integrated with Rails patterns while maintaining all current functionality.

## Timeline Estimate

- **Phase 1**: 1-2 days (setup)
- **Phase 2**: 2-3 days (server-side architecture)
- **Phase 3**: 2-3 days (Turbo integration)
- **Phase 4**: 2-3 days (custom component)
- **Phase 5**: 1-2 days (migration strategy)

**Total**: ~8-13 days for complete migration

## Success Criteria

- [ ] All tables load only needed data (20-50 records per page)
- [ ] Pagination works without full page reloads
- [ ] Search functionality preserved and enhanced
- [ ] Sort functionality works server-side
- [ ] Performance improvement measurable
- [ ] No JavaScript errors or accessibility regressions
- [ ] URLs are bookmarkable and shareable
- [ ] Graceful degradation without JavaScript