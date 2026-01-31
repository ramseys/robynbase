# Tracks the display order of images attached to Gigs and Compositions.
# Uses a separate table rather than modifying the Rails-managed active_storage_attachments table.
class ImageOrdering < ApplicationRecord
  belongs_to :attachment, class_name: 'ActiveStorage::Attachment'
end
