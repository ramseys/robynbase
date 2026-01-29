# Plan: Drag-and-Drop Image Table Reordering

## Current State

- **Partial**: `app/views/robyn/_image_table.erb` (shared between Gigs and Compositions)
- **Storage**: Uses Active Storage `has_many_attached :images`
- **Ordering**: None - images display in attachment creation order (`created_at`)
- **No position field** exists in the Active Storage tables

## Recommended Approach: Add `position` column to `active_storage_attachments`

### Implementation Steps

| Step | File | Action |
|------|------|--------|
| 1 | `db/migrate/xxx_add_position_to_active_storage_attachments.rb` | Add `position` integer column with default |
| 2 | `app/models/gig.rb` | Add scope to order images by position |
| 3 | `app/models/composition.rb` | Same ordering scope |
| 4 | `app/views/robyn/_image_table.erb` | Add sortable controller, drag handles, hidden position field |
| 5 | `app/controllers/gigs_controller.rb` | Handle position updates on save |
| 6 | `app/controllers/compositions_controller.rb` | Same position handling |

### Step 1: Migration

```ruby
class AddPositionToActiveStorageAttachments < ActiveRecord::Migration[7.0]
  def change
    add_column :active_storage_attachments, :position, :integer, default: 0

    # Set initial positions based on current order
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE active_storage_attachments a
          JOIN (
            SELECT id, ROW_NUMBER() OVER (PARTITION BY record_type, record_id, name ORDER BY created_at) as pos
            FROM active_storage_attachments
          ) ranked ON a.id = ranked.id
          SET a.position = ranked.pos
        SQL
      end
    end
  end
end
```

### Step 2-3: Model Changes

```ruby
# In gig.rb and composition.rb
has_many_attached :images, dependent: :destroy

def ordered_images
  images.includes(:blob).order(position: :asc)
end
```

### Step 4: View Changes

```erb
<table class="image-table sortable-table">
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
        <td style="text-align: center">
          <%= check_box_tag "deleted_img_ids[]", img.id %>
        </td>
        <td>
          <!-- image display -->
        </td>
      </tr>
    <% end %>
  </tbody>
</table>
```

### Step 5-6: Controller Changes

```ruby
# In gigs_controller.rb and compositions_controller.rb

def update
  # ... existing code ...

  update_image_positions if params[:image_positions].present?

  # ... rest of update ...
end

private

def update_image_positions
  params[:image_positions].each do |attachment_id, position|
    ActiveStorage::Attachment.where(id: attachment_id).update_all(position: position)
  end
end
```

### Considerations

1. **Shared partial** - Changes must work for both Gigs and Compositions
2. **Existing images** - Migration sets default positions based on current `created_at` order
3. **New uploads** - Need to assign position when new images are attached (max position + 1)
4. **Sortable controller** - Reuse the existing `sortable_controller.js` with `field-value="position"`

### Alternative Approaches (Not Recommended)

- **Option 2**: Store order in parent model as JSON array of blob IDs
- **Option 3**: Use blob metadata field to store position

These are more complex and don't integrate as cleanly with the existing sortable controller pattern.
