# Shared controller logic for handling image ordering.
# Include this in controllers that manage models with OrderableImages.
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
