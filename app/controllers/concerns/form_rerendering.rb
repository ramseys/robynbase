# Shared by the category editors (Gig, Release, Song, Venue): after a failed save,
# re-render the new/edit form with the submitted values (from the unsaved record) and
# its validation errors, rather than losing the user's input.
module FormRerendering
  extend ActiveSupport::Concern

  private

  # The 422 status is required: Turbo ignores a 200 response to a form submission.
  def render_form_with_errors(template)
    load_form_options
    render template, status: :unprocessable_content
  end

  # Hook for anything the new/edit forms need besides the record itself (e.g. the
  # song dropdown). Nothing by default.
  def load_form_options
  end

end
