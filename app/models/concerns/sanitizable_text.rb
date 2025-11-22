# frozen_string_literal: true

# Provides HTML sanitization for user-generated content
# Allows safe formatting tags while preventing XSS attacks
module SanitizableText
  extend ActiveSupport::Concern

  # Safe HTML tags that are allowed in user content
  SAFE_TAGS = %w[br p strong em b i u ul ol li a blockquote].freeze

  # Safe HTML attributes that are allowed
  SAFE_ATTRIBUTES = %w[href].freeze

  included do
    # Store fields to sanitize at class level
    class_attribute :sanitizable_fields, default: []

    # Automatically sanitize configured fields before saving
    before_save :sanitize_configured_fields
  end

  class_methods do
    # Define which fields should be sanitized on save
    # Example: sanitize_fields :Comments, :Lyrics
    def sanitize_fields(*fields)
      self.sanitizable_fields = fields
    end
  end

  # Sanitize HTML content, allowing safe tags while blocking XSS
  # Also converts newlines to <br> tags for proper display
  def sanitize_html(text)
    return nil if text.blank?

    ActionController::Base.helpers.sanitize(
      text.gsub(/\r\n|\n/, '<br>'),
      tags: SAFE_TAGS,
      attributes: SAFE_ATTRIBUTES
    )
  end

  private

  # Sanitize all configured fields before saving
  def sanitize_configured_fields
    self.class.sanitizable_fields.each do |field|
      field_value = send(field)
      send("#{field}=", sanitize_html(field_value)) if field_value.present?
    end
  end
end
