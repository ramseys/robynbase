# Concern for controllers that need image upload functionality
# Provides common methods for handling image optimization and deletion
module ImageAttachable
  extend ActiveSupport::Concern

  included do
    include ImageUtils
  end

  # Handle image optimization and purging in update/create actions
  #
  # @param params [ActionController::Parameters] The params hash containing image data
  # @param purge [Boolean] Whether to purge images marked for deletion
  def process_images(params, purge: false)
    purge_marked_images(params) if purge
    optimize_images(params)
  end

  # Returns hash of permitted image parameters for use in strong params
  #
  # @return [Hash] Hash containing :images and :deleted_img_ids keys
  def image_params
    { images: [], deleted_img_ids: [] }
  end
end
