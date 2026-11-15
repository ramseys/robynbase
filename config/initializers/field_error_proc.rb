# How form fields with validation errors are marked.
#
# Rails' default wraps every errored label and input in <div class="field_with_errors">.
# That div is a block element, so it breaks inline layouts (e.g. the "required"
# asterisk after a label drops onto its own line), and nothing styles it anyway.
# Instead, leave labels untouched and add Bootstrap's `is-invalid` class to the
# input/select/textarea, which gives it Bootstrap's red invalid styling. The messages
# themselves are listed at the top of the form (app/views/shared/_form_errors.html.erb).
ActionView::Base.field_error_proc = proc do |html_tag, _instance|
  fragment = Nokogiri::HTML5::DocumentFragment.parse(html_tag)
  field = fragment.children.first

  if field && %w[input select textarea].include?(field.name) && field["type"] != "hidden"
    field["class"] = [field["class"], "is-invalid"].compact.join(" ")
    fragment.to_html.html_safe
  else
    html_tag
  end
end
