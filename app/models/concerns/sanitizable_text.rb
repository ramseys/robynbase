# frozen_string_literal: true

# Provides HTML sanitization for user-generated content
# Allows safe formatting tags while preventing XSS attacks
module SanitizableText
  extend ActiveSupport::Concern

  # Safe HTML tags that are allowed in user content
  SAFE_TAGS = %w[br p strong em b i u ul ol li a blockquote iframe].freeze

  # Safe HTML attributes that are allowed
  SAFE_ATTRIBUTES = %w[href src width height frameborder title].freeze

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

  IFRAME_SANDBOX = 'allow-scripts allow-same-origin'

  # Sanitize HTML content, allowing safe tags while blocking XSS
  # Also converts newlines to <br> tags for proper display
  def sanitize_html(text)
    return nil if text.blank?

    sanitized = ActionController::Base.helpers.sanitize(
      text,
      tags: SAFE_TAGS,
      attributes: SAFE_ATTRIBUTES
    )
    enforce_iframe_sandbox(sanitized)
  end

  def enforce_iframe_sandbox(html)
    return html if html.blank?

    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.css('iframe').each { |iframe| iframe['sandbox'] = IFRAME_SANDBOX }
    doc.to_html
  end
  
  # Add explicit html <br>s for linebreaks
  def add_linebreaks(text)
    text&.gsub(/\r\n|\n/, '<br>')
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
