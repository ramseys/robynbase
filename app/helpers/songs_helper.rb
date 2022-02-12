module SongsHelper

  def highlight_search_lyrics(search, lyrics)

     first = lyrics.index(/#{Regexp.quote(search)}/i)
     last = first + search.length
    
     # grab the fragment of the lyrics that contain the search term
     fragment_first = [0, first - 50].max
     fragment_last  = [lyrics.length - 1, last + 50].min
     fragment = lyrics.slice(fragment_first .. fragment_last)

     # highlight the search term
     highlighted_fragment = fragment.gsub(/#{Regexp.quote(search)}/i, '<b>\0</b>')

     # add ellipses where necessary
     highlighted_fragment.prepend "... " unless fragment_first == 0
     highlighted_fragment.concat " ..." unless fragment_last == 0

     highlighted_fragment.html_safe 

  end

  def show_lyrics(song)
    song.Lyrics.present? and song.show_lyrics
  end

end
