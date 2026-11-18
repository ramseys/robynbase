# The default form builder for every form in the app (set in ApplicationController).
#
# It adds Bootstrap's `is-invalid` class to a field whose record has a validation error
# for it, which gives the field Bootstrap's red invalid styling. The error messages
# themselves are listed at the top of the form (app/views/shared/_form_errors.html.erb).
# Each override only adds the class to the options and hands off to Rails' own helper,
# which renders the field as usual.
#
# A field whose error is recorded under a different attribute than the one it edits
# names that attribute with `errors_from:`, e.g. the gig's VENUEID select, whose error
# is on the :venue association:
#
#   f.select :VENUEID, venues, {}, { class: "form-control", errors_from: :venue }
#
# Only the field helpers the forms use are covered (hidden fields never show errors).
# A form that starts using another one (e.g. number_field) needs an override here, or
# its errored fields won't be flagged.
class ApplicationFormBuilder < ActionView::Helpers::FormBuilder

  def text_field(method, options = {})
    super(method, with_error_class(method, options))
  end

  def text_area(method, options = {})
    super(method, with_error_class(method, options))
  end

  def date_field(method, options = {})
    super(method, with_error_class(method, options))
  end

  # the class goes on the visible checkbox, not the hidden input Rails puts before it
  def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
    super(method, with_error_class(method, options), checked_value, unchecked_value)
  end

  # the class belongs in html_options; options holds select's own settings (include_blank etc.)
  def select(method, choices = nil, options = {}, html_options = {}, &block)
    super(method, choices, options, with_error_class(method, html_options), &block)
  end

  private

  # A copy of the field's options, without errors_from: and with is-invalid added to
  # its class when the record has an error for the field
  def with_error_class(method, options)
    error_attribute = options.fetch(:errors_from, method)
    field_options = options.except(:errors_from)

    if object.respond_to?(:errors) && object.errors.include?(error_attribute)
      field_options[:class] = [*field_options[:class], "is-invalid"]
    end

    field_options
  end

end
