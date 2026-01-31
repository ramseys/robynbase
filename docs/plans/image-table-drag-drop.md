# Plan: Drag-and-Drop Image Table Reordering

## Current State

- **Partial**: `app/views/robyn/_image_table.erb` (shared between Gigs and Compositions)
- **Storage**: Uses Active Storage `has_many_attached :images`
- **Ordering**: None - images display in attachment creation order (`created_at`)
- **No position field** exists in the Active Storage tables

## Recommended Approach: Create `image_orderings` intermediary table

Rather than modifying the Rails-managed `active_storage_attachments` table, we create a separate table to track position. This keeps Active Storage tables pristine and avoids potential issues with future Rails upgrades.

### Data Model

```
image_orderings
├── id
├── attachment_id  →  active_storage_attachments.id
├── position
└── timestamps

active_storage_attachments (unchanged, Rails-managed)
├── id
├── record_type    ("Gig" or "Composition")
├── record_id      (GIGID or COMPID)
├── name           ("images")
├── blob_id
└── created_at
```

### Implementation Steps

| Step | File | Action |
|------|------|--------|
| 1 | `db/migrate/xxx_create_image_orderings.rb` | Create `image_orderings` table |
| 2 | `app/models/image_ordering.rb` | New model for image ordering |
| 3 | `app/models/concerns/orderable_images.rb` | Shared concern for Gig and Composition |
| 4 | `app/models/gig.rb` | Include the concern |
| 5 | `app/models/composition.rb` | Include the concern |
| 6 | `app/views/robyn/_image_table.erb` | Add sortable controller, drag handles, Remove button |
| 7 | `app/javascript/controllers/image_table_controller.js` | Handle Remove button clicks |
| 8 | `app/controllers/concerns/image_ordering_concern.rb` | Shared controller logic |
| 9 | `app/controllers/gigs_controller.rb` | Include the concern |
| 10 | `app/controllers/compositions_controller.rb` | Include the concern |

### Step 1: Migration

```ruby
class CreateImageOrderings < ActiveRecord::Migration[7.2]
  def change
    create_table :image_orderings do |t|
      t.references :attachment, null: false, foreign_key: { to_table: :active_storage_attachments }
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :image_orderings, [:attachment_id], unique: true

    # Create initial ordering records for existing attachments
    reversible do |dir|
      dir.up do
        execute <<-SQL
          INSERT INTO image_orderings (attachment_id, position, created_at, updated_at)
          SELECT id,
                 ROW_NUMBER() OVER (PARTITION BY record_type, record_id, name ORDER BY created_at),
                 NOW(),
                 NOW()
          FROM active_storage_attachments
          WHERE name = 'images'
        SQL
      end
    end
  end
end
```

### Step 2: ImageOrdering Model

```ruby
# app/models/image_ordering.rb
class ImageOrdering < ApplicationRecord
  belongs_to :attachment, class_name: 'ActiveStorage::Attachment'
end
```

### Step 3: Shared Concern for Models

```ruby
# app/models/concerns/orderable_images.rb
module OrderableImages
  extend ActiveSupport::Concern

  included do
    has_many_attached :images, dependent: :destroy
  end

  def ordered_images
    images
      .joins("JOIN image_orderings ON image_orderings.attachment_id = active_storage_attachments.id")
      .includes(:blob)
      .order("image_orderings.position")
  end
end
```

Note: Position assignment is handled in the controller layer (see Step 8), following the same pattern as setlist and media ordering.

### Step 4-5: Model Changes

```ruby
# In gig.rb
class Gig < ApplicationRecord
  include OrderableImages
  # ... rest of model
end

# In composition.rb
class Composition < ApplicationRecord
  include OrderableImages
  # ... rest of model
end
```

### Step 6: View Changes

```erb
<%# app/views/robyn/_image_table.erb %>
<% if object.images.attached? %>

  <table class="image-table sortable-table" data-controller="image-table">
    <thead>
      <tr>
        <th></th>
        <th></th>
        <th></th>
        <th>Action</th>
      </tr>
    </thead>

    <tbody data-controller="sortable" data-sortable-field-value="position">
      <% object.ordered_images.each_with_index do |img, index| %>
        <tr data-attachment-id="<%= img.id %>">
          <td class="drag-handle">
            <i class="bi bi-grip-vertical"></i>
            <input type="hidden"
                   name="image_positions[<%= img.id %>]"
                   value="<%= index + 1 %>"
                   data-field="position">
          </td>
          <td><%= index + 1 %></td>
          <td>
            <div class="image-cell">
              <% if img.variable? %>
                <%= image_tag img.variant(resize: "100x100") %>
              <% else %>
                <%= image_tag img, height: "100px" %>
              <% end %>
            </div>
          </td>
          <td>
            <button type="button" class="btn btn-link"
                    data-action="click->image-table#removeImage"
                    data-attachment-id="<%= img.id %>">
              Remove
            </button>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>

  <%# Container for hidden fields tracking deleted images %>
  <div data-image-table-target="deletions"></div>

<% end %>

<br/>
<%= form.file_field :images, multiple: true %>
```

### Step 7: JavaScript Controller

```javascript
// app/javascript/controllers/image_table_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["deletions"]

  removeImage(event) {
    const button = event.currentTarget
    const attachmentId = button.dataset.attachmentId
    const row = button.closest("tr")

    // Remove the row from the table
    row.remove()

    // Add a hidden field to track this deletion
    const hiddenField = document.createElement("input")
    hiddenField.type = "hidden"
    hiddenField.name = "deleted_img_ids[]"
    hiddenField.value = attachmentId
    this.deletionsTarget.appendChild(hiddenField)
  }
}
```

This approach:
- Removes the row immediately for visual feedback
- Adds a hidden field to track the deletion
- Uses the existing `purge_marked_images` backend logic (no controller changes needed for deletion)
- Changes aren't final until the form is saved (user can "undo" by not saving)

### Step 8: Shared Controller Concern

```ruby
# app/controllers/concerns/image_ordering_concern.rb
module ImageOrderingConcern
  extend ActiveSupport::Concern

  private

  # Update positions for existing images based on form order
  def update_image_positions
    return unless params[:image_positions].present?

    params[:image_positions].each do |attachment_id, position|
      ImageOrdering.find_or_initialize_by(attachment_id: attachment_id).update(position: position)
    end
  end

  # Assign positions to newly uploaded images (appended after existing images)
  def assign_positions_to_new_images(record)
    max_position = ImageOrdering
      .joins("JOIN active_storage_attachments asa ON asa.id = image_orderings.attachment_id")
      .where("asa.record_type = ? AND asa.record_id = ? AND asa.name = 'images'", record.class.name, record.id)
      .maximum(:position) || 0

    record.images.each do |img|
      unless ImageOrdering.exists?(attachment_id: img.id)
        max_position += 1
        ImageOrdering.create(attachment_id: img.id, position: max_position)
      end
    end
  end
end
```

### Step 9-10: Controller Changes

```ruby
# In gigs_controller.rb and compositions_controller.rb
include ImageOrderingConcern

def update
  # ... existing code ...

  # Purge images marked for removal (existing logic via ImageUtils)
  purge_marked_images(params)

  # After attaching new images:
  record.images.attach(images) if images.present?
  assign_positions_to_new_images(record)

  # Update positions for reordered images:
  update_image_positions

  # ... rest of update ...
end
```

### Considerations

1. **Shared partial** - Changes work for both Gigs and Compositions via the polymorphic attachment table
2. **Existing images** - Migration creates ordering records based on current `created_at` order
3. **New uploads** - Controller assigns positions (max + 1) after attaching, following setlist/media pattern
4. **Sortable controller** - Reuse the existing `sortable_controller.js` with `field-value="position"`
5. **Image deletion** - "Remove" button follows same pattern as setlist/media tables; uses existing `purge_marked_images` backend
6. **Orphan cleanup** - When images are purged, their `image_orderings` records should also be deleted (consider `dependent: :destroy` or database cascade)

### Why Not Modify `active_storage_attachments`?

- It's a Rails-managed table; future upgrades might conflict
- Other gems interacting with Active Storage won't expect custom columns
- Keeps framework tables pristine and your customizations isolated
