# Venue Image Uploads Implementation Plan

## Overview
This document outlines the plan to add image upload functionality to Venues, following the existing patterns used for Gigs and Releases. It also includes recommendations for improving the image compression mechanism across all entity types.

---

## Current Implementation Analysis

### Technology Stack
- **ActiveStorage** (Rails 7.2 built-in) for file storage
- **MiniMagick** for image processing
- **image_processing** gem (already installed)
- Disk-based storage in `/active-storage-files/`

### Common Pattern Across Gigs & Releases

#### Models
Both `gig.rb:17` and `composition.rb:7` use:
```ruby
has_many_attached :images, :dependent => :destroy
```

#### Controllers
All controllers with image uploads:
- Include `ImageUtils` module
- Call `optimize_images(params)` in `create` action
- Call `purge_marked_images(params)` + `optimize_images(params)` in `update` action
- Permit `images: []` and `deleted_img_ids: []` in strong params

#### Views
- **Form**: Render `/robyn/image_table` partial with `:object` and `:form` locals
- **Show**: Render `/robyn/image_section` partial with `:object` local

---

## Image Compression Assessment

### Current Approach
The `optimize_images()` method in `app/modules/ImageUtils.rb:4-20`:
- Only resizes images larger than 1200x1200 pixels
- Uses MiniMagick's `resize` method (maintains aspect ratio)
- **No explicit quality/compression settings**
- No metadata stripping

### Current Results
- Typical reduction: 7MB → ~143KB (resize only)

---

## Recommendations for Better Compression

### Option 1: Add Quality Settings (Recommended - Start Here)
**Immediate improvement, no infrastructure changes required**

```ruby
def optimize_images(params)
  if params[:images].present?
    params[:images].each do |image|
      mini_image = MiniMagick::Image.new(image.tempfile.path)

      if mini_image.width > 1200 || mini_image.height > 1200
        mini_image.resize '1200x1200'
      end

      # Add quality compression (80-85 is a good balance)
      mini_image.quality 85

      # Strip metadata to reduce file size
      mini_image.strip

      # For JPEG, use progressive encoding
      mini_image.interlace 'Plane' if mini_image.type =~ /jpe?g/i
    end
  end
end
```

**Benefits**:
- Quality 85 typically reduces file size by 30-50% with no visible quality loss
- Stripping metadata can save 10-20KB per image
- Progressive JPEGs load faster on web
- **Expected result**: 7MB → ~70-100KB (50% smaller than current)

### Option 2: Switch to libvips (Better Performance)
**Better performance, already supported by Rails 7.2**

```ruby
# In ImageUtils module
require 'image_processing/vips'

def optimize_images(params)
  if params[:images].present?
    params[:images].each do |image|
      ImageProcessing::Vips
        .source(image.tempfile.path)
        .resize_to_limit(1200, 1200)
        .saver(quality: 85, strip: true)
        .call(destination: image.tempfile.path)
    end
  end
end
```

**Benefits**:
- **4-10x faster** processing
- **Uses 90% less memory** than MiniMagick
- Better compression algorithms (especially for PNG)
- Already the default in Rails 7
- Same file size as Option 1

**Requirement**: `libvips` must be installed on server (check with `vips --version`)

### Option 3: Add image_optim gem (Advanced)
**For maximum compression without quality loss**

```ruby
# Gemfile
gem 'image_optim'
gem 'image_optim_pack'  # Precompiled binaries
```

**Benefits**:
- Additional 10-30% size reduction with **zero quality loss**
- Optimizes PNG/JPEG encoding
- Can be combined with Options 1 or 2

### Compression Comparison Summary

| Method | File Size | Processing Speed | Quality | Infrastructure Change |
|--------|-----------|------------------|---------|----------------------|
| Current (resize only) | ~143KB | Baseline | Good | None |
| + Quality settings | ~70-100KB | Same | Good | None |
| + libvips | ~70-100KB | 4-10x faster | Good | Install libvips |
| + image_optim | ~50-80KB | Slightly slower | Excellent | Additional gem |

**Recommendation**: Start with **Option 1** for immediate improvement, then consider **Option 2** if performance becomes an issue.

---

## Refactoring Plan: Extract Common Code

### Create ImageAttachable Concern

**File**: `app/controllers/concerns/image_attachable.rb` (NEW)

```ruby
module ImageAttachable
  extend ActiveSupport::Concern

  included do
    include ImageUtils
  end

  # Handle image optimization and purging in update/create actions
  def process_images(params, purge: false)
    purge_marked_images(params) if purge
    optimize_images(params)
  end

  # Add image parameters to strong params
  def image_params
    { images: [], deleted_img_ids: [] }
  end
end
```

**Usage**: Replace `include ImageUtils` with `include ImageAttachable` in controllers

**Benefits**:
- Reduces code duplication
- Centralizes image handling logic
- Easier to maintain and update

---

## Implementation Plan for Venue Image Uploads

### Step 1: Update Venue Model

**File**: `app/models/venue.rb:7` (after `has_many :gigs` line)

```ruby
has_many :gigs, -> { order('GIG.GigDate ASC') }, foreign_key: "VENUEID"
has_many_attached :images, :dependent => :destroy
```

---

### Step 2: Update VenuesController

#### 2a. Add ImageUtils Module
**File**: `app/controllers/venues_controller.rb:2` (after `include Paginated`)

```ruby
class VenuesController < ApplicationController
  include Paginated
  include InfiniteScrollConcern
  include ImageUtils  # ADD THIS LINE
```

#### 2b. Update create Action
**File**: `app/controllers/venues_controller.rb:49`

```ruby
def create
  filtered_params = prepare_params

  optimize_images(filtered_params)  # ADD THIS LINE

  @venue = Venue.new(filtered_params)

  if @venue.save
    return_to_previous_page(@venue)
  else
    render "new"
  end
end
```

#### 2c. Update update Action
**File**: `app/controllers/venues_controller.rb:36`

```ruby
def update
  venue = Venue.find(params[:id])
  filtered_params = prepare_params

  purge_marked_images(params)        # ADD THIS LINE
  optimize_images(filtered_params)   # ADD THIS LINE

  venue.update!(filtered_params)
  return_to_previous_page(venue)
end
```

#### 2d. Update venue_params Method
**File**: `app/controllers/venues_controller.rb:128`

```ruby
def venue_params
  params.require(:venue).
    permit(:Name, :street_address1, :street_address2, :City, :SubCity,
           :State, :Country, :longitude, :latitude, :Notes,
           :images, images: [], deleted_img_ids: [])  # ADD images params
    .tap do |params|
      params.require([:Name, :City, :Country])
    end
end
```

---

### Step 3: Update Venue Form View

**File**: `app/views/venues/_venue_form.erb:77` (after Notes field, before submit button)

```erb
<div class="row">
  <div class="col-sm-12">
    <%= f.label :Notes %>
    <%= f.text_area :Notes, :cols => 60, :rows => 5, :class => "form-control"  %>
  </div>
</div>

<br>

<!-- ADD THIS SECTION -->
<!-- image attachments -->
<div class="row">
  <div class="col-sm-12">
    <h3>Images</h3>
    <%= render partial: '/robyn/image_table', :locals => {:object => @venue, :form => f} %>
  </div>
</div>
<!-- END NEW SECTION -->

<%= f.submit "Save", class: "btn btn-large btn-primary" %>
```

---

### Step 4: Update Venue Show View

#### 4a. Add Images Section
**File**: `app/views/venues/show.html.erb:38` (after map section, before Details section)

```erb
<% end %>

<!-- ADD THIS SECTION -->
<% if @venue.images.attached? %>
  <%= render :partial => 'robyn/image_section', :locals => { object: @venue } %>
<% end %>
<!-- END NEW SECTION -->

<div>
  <h3 class="section-header">Details</h4>
```

**Note**: The existing `.image-container` CSS class (robyn.css.scss:535-548) already handles:
- Images float right on screens ≥700px wide
- Proper spacing and responsive behavior
- No additional CSS changes needed!

#### 4b. Update In-Page Navigation
**File**: `app/views/venues/show.html.erb:10-13`

```erb
<small>
  <span class="inpage-navigation">
    <% if @venue.images.attached? %> <span><a href="#images">Images</a></span> <% end %>
    <% if @venue.get_notes.present? %> <span><a href="#notes">Notes</a></span> <% end %>
    <% if @venue.gigs.present? %> <span><a href="#gigs">Gigs</a></span> <% end %>
  </span>
</small>
```

---

### Step 5 (Optional): Add Quick Query for Venues with Images

#### 5a. Add Quick Query Definition
**File**: `app/models/venue.rb:14`

```ruby
@@quick_queries = [
  QuickQuery.new('venues', :with_notes, [:without]),
  QuickQuery.new('venues', :with_location, [:without]),
  QuickQuery.new('venues', :with_images),  # ADD THIS
]
```

#### 5b. Add Quick Query Method
**File**: `app/models/venue.rb:111` (after `quick_query_venues_with_location`)

```ruby
def self.quick_query_venues_with_images
  joins("JOIN active_storage_attachments asa")
    .where("asa.record_type = 'Venue' and asa.record_id = VENUE.VENUEID")
    .distinct
    .then { |venues| prepare_query(venues) }
end
```

#### 5c. Update quick_query Switch
**File**: `app/models/venue.rb:79`

```ruby
def self.quick_query(id, secondary_attribute)
  case id
    when :with_notes.to_s
      venues = quick_query_venues_with_notes(secondary_attribute)
    when :with_location.to_s
      venues = quick_query_venues_with_location(secondary_attribute)
    when :with_images.to_s                        # ADD THIS
      venues = quick_query_venues_with_images     # ADD THIS
  end
  venues
end
```

---

## Summary of Changes

### Required Changes (Minimum for functionality)
- [x] Add `has_many_attached :images` to Venue model
- [x] Include `ImageUtils` in VenuesController
- [x] Add `optimize_images()` and `purge_marked_images()` calls to controller actions
- [x] Update `venue_params` to permit image parameters
- [x] Add image upload section to venue form
- [x] Add image display section to venue show page
- [x] Update in-page navigation to include images link

### Optional Improvements
- [ ] Improve `ImageUtils.optimize_images()` with quality settings
- [ ] Consider switching to libvips for better performance
- [ ] Create `ImageAttachable` concern to reduce code duplication
- [ ] Add quick query for venues with images

---

## Testing Checklist

After implementation, verify:

1. **Image Upload**
   - [ ] Can upload multiple images when creating a new venue
   - [ ] Can upload multiple images when editing an existing venue
   - [ ] Images are resized to max 1200x1200 if larger
   - [ ] File sizes are reasonable (~100KB or less for typical photos)

2. **Image Display**
   - [ ] Images display on venue show page
   - [ ] Images float to the right on desktop (≥700px wide)
   - [ ] Images appear inline on mobile (<700px wide)
   - [ ] Click on image opens lightbox gallery
   - [ ] Multiple images show "Click to see X images in gallery" text
   - [ ] In-page navigation link to images appears when images exist

3. **Image Deletion**
   - [ ] Can select images for deletion in edit form
   - [ ] Selected images are actually removed after save
   - [ ] Deletion doesn't affect images on other venues

4. **Edge Cases**
   - [ ] Venue without images displays correctly (no broken layout)
   - [ ] Venue with map AND images displays both correctly
   - [ ] Very large images (>10MB) are handled gracefully
   - [ ] Non-image files are rejected or handled appropriately

---

## File Reference

### Files to Modify
1. `app/models/venue.rb`
2. `app/controllers/venues_controller.rb`
3. `app/views/venues/_venue_form.erb`
4. `app/views/venues/show.html.erb`

### Files to Optionally Create
1. `app/controllers/concerns/image_attachable.rb`

### Files to Optionally Modify
1. `app/modules/ImageUtils.rb` (for improved compression)

### Existing Files (No Changes Needed)
1. `app/views/robyn/_image_table.erb` (reusable partial)
2. `app/views/robyn/_image_section.erb` (reusable partial)
3. `app/assets/stylesheets/robyn.css.scss` (styling already exists)

---

## Implementation Order

1. **Basic Functionality** (Required)
   - Step 1: Update Venue Model
   - Step 2: Update VenuesController
   - Step 3: Update Venue Form View
   - Step 4: Update Venue Show View

2. **Enhanced Features** (Optional)
   - Step 5: Add Quick Query for Venues with Images
   - Improve image compression (Option 1)
   - Create ImageAttachable concern

3. **Performance Optimization** (If Needed)
   - Switch to libvips (Option 2)
   - Add image_optim gem (Option 3)

---

## Git Branch

All changes should be developed on branch: `claude/add-venue-image-uploads-017wCMi3XsZWQX5Ef7oCnxkC`

---

*Plan created: 2025-11-16*
