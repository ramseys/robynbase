# Shared by the Gig, Release and Venue controllers: the image half of a form
# submission (new uploads, removals and reordering), for models with OrderableImages.
#
# Call these only once the record has saved, so a failed save doesn't lose or waste
# anything: an image marked for removal is still there when the form is re-rendered.
module ImageFormHandling
  extend ActiveSupport::Concern

  private

  # Optimizes the newly uploaded images, attaches them, and assigns their positions.
  # They're attached rather than assigned through the model, because assigning
  # replaces the record's existing images instead of appending to them.
  def attach_new_images(record, images)
    if images.present?
      optimize_images(images)
      record.images.attach(images)
    end
    assign_positions_to_new_images(record)
  end

  # Purges the images marked for removal. Only the record's own images can be purged,
  # so an id belonging to another record (or another kind of attachment) is ignored.
  def purge_marked_images(record, params)
    attachments = record.images_attachments.where(id: params[:deleted_img_ids])
    attachments.each(&:purge)
  end

  # Update positions for existing images based on form order
  def update_image_positions
    return unless params[:image_positions].present?

    params[:image_positions].each do |attachment_id, position|
      ImageOrdering.find_or_initialize_by(attachment_id: attachment_id).update(position: position)
    end
  end

  # --- internal steps ---

  # Reduces large images to a maximum width/height of 1200 pixels, in place
  def optimize_images(images)
    images.each do |image|
      # skip non-image files (e.g., videos)
      next unless image.content_type.start_with?('image/')

      mini_image = MiniMagick::Image.new(image.tempfile.path)

      if mini_image.width > 1200 || mini_image.height > 1200
        mini_image.resize '1200x1200'
      end
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
