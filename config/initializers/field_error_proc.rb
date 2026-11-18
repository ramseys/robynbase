# How form fields with validation errors are marked.
#
# Rails' default wraps every errored label and field in <div class="field_with_errors">.
# That div is a block element, so it breaks inline layouts (e.g. the "required"
# asterisk after a label drops onto its own line), and nothing styles it anyway. So
# leave the HTML unchanged here: ApplicationFormBuilder adds Bootstrap's `is-invalid`
# class to errored fields instead.
ActionView::Base.field_error_proc = proc { |html_tag, _instance| html_tag }
