# Shared by the Gig and Release (composition) editors, whose setlist and track rows
# offer a song dropdown. The list is needed by the new/edit pages, and again whenever
# a failed save re-renders the form.
module SongListLoading
  extend ActiveSupport::Concern
  include FormRerendering

  private

  def load_song_list
    @song_list = Song.order(:Song).collect{|s| [s.full_name, s.SONGID]}
  end

  def load_form_options
    load_song_list
  end

end
