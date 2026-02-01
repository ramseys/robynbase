# Provides ordered image functionality for models with has_many_attached :images.
# Position assignment is handled in the controller layer (see ImageOrderingConcern),
# following the same pattern as setlist and media ordering.
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
