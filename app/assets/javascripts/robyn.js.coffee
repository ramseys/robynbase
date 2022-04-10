# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/



substringMatcher = (strs) ->
  return (q, cb) ->

    # an array that will be populated with substring matches
    matches = []
 
    # regex used to determine if a string contains the substring `q`
    substrRegex = new RegExp(q, 'i')
 
    # iterate through the pool of strings and for any string that
    # contains the substring `q`, add it to the `matches` array
    $.each(strs, (i, str) ->
      if substrRegex.test(str)
        # the typeahead jQuery plugin expects suggestions to a
        # JavaScript object, refer to typeahead docs for more info
        matches.push({ search_value: str });
      
    );
 
    cb(matches)
  


$(window).on("load", -> 

  currentPage = window.location.pathname.substring(1);

  activeTab = switch
    when currentPage == "" then "robyn-home"
    when currentPage.indexOf("songs") == 0 then "robyn-songs"
    when currentPage.indexOf("compositions") == 0 then "robyn-compositions"
    when currentPage.indexOf("gigs") == 0 then "robyn-gigs"
    when currentPage.indexOf("venues") == 0 then "robyn-venues"
    when currentPage.indexOf("performances") == 0 then "robyn-performances"
    when currentPage.indexOf("about") == 0 then "robyn-about"
    else "robyn-home"

  $("##{activeTab}").addClass("active")

  $("#search_value").on("keypress", (e) ->

    if e.which == 10 or e.which == 13
      $("#main-search").submit();

  )

  # note that this event is delegated to the body of main search tables, and selectes for tr's; 
  # we need to do this (instead of attaching the events to the rows directly) because the rows might
  # not be there when this event handler is declared (eg, because of grid paging)
  $(".main-search-list tbody").on("click", "tr", (e) ->

    # don't navigate if click is on one of the actions
    if e.target and e.target.nodeName != "A"
      window.location = $(e.currentTarget).data("path")

  )
   

  song_engine = new Bloodhound({
    # name: 'all'
    # local: [{ val: 'dog' }, { val: 'pig' }, { val: 'moose' }],
    remote:
      url: '/robyn/search?utf8=%E2%9C%93&search_value=%QUERY'
      filter: (results) ->
        $.map(results, (result, index) ->
          prefix = if result.Prefix then (result.Prefix + " ") else ""
          return {search_value: prefix + result.Song, id: result.SONGID}
        )
    datumTokenizer: (d) -> 
      console.log(d)
      return Bloodhound.tokenizers.whitespace(d.search_value)
    queryTokenizer: Bloodhound.tokenizers.whitespace
    
  });

  gig_engine = new Bloodhound({
    # name: 'all'
    # local: [{ val: 'dog' }, { val: 'pig' }, { val: 'moose' }],
    remote:
      url: '/robyn/search_gigs?utf8=%E2%9C%93&search_value=%QUERY'
      filter: (results) ->
        $.map(results, (result, index) ->
          return {search_value: result.Venue, id: result.GIGID}
        )
    datumTokenizer: (d) -> 
      console.log(d)
      return Bloodhound.tokenizers.whitespace(d.search_value)
    queryTokenizer: Bloodhound.tokenizers.whitespace
    
  });

  composition_engine = new Bloodhound({
    # name: 'all'
    # local: [{ val: 'dog' }, { val: 'pig' }, { val: 'moose' }],
    remote:
      url: '/robyn/search_compositions?utf8=%E2%9C%93&search_value=%QUERY'
      filter: (results) ->
        $.map(results, (result, index) ->
          return {search_value: result.Title, id: result.COMPID}
        )
    datumTokenizer: (d) -> 
      console.log(d)
      return Bloodhound.tokenizers.whitespace(d.search_value)
    queryTokenizer: Bloodhound.tokenizers.whitespace
    
  });

  venue_engine = new Bloodhound({
    # name: 'all'
    # local: [{ val: 'dog' }, { val: 'pig' }, { val: 'moose' }],
    remote:
      url: '/robyn/search_venues?utf8=%E2%9C%93&search_value=%QUERY'
      filter: (results) ->
        $.map(results, (result, index) ->
          return {search_value: result.Name, id: result.VENUEID}
        )
    datumTokenizer: (d) -> 
      console.log(d)
      return Bloodhound.tokenizers.whitespace(d.search_value)
    queryTokenizer: Bloodhound.tokenizers.whitespace
    
  });

  performance_engine = new Bloodhound({
    # name: 'all'
    # local: [{ val: 'dog' }, { val: 'pig' }, { val: 'moose' }],
    remote:
      url: '/robyn/search_performances?utf8=%E2%9C%93&search_value=%QUERY'
      filter: (results) ->
        $.map(results, (result, index) ->
          return {search_value: result.name, id: result.performanceid}
        )
    datumTokenizer: (d) -> 
      console.log(d)
      return Bloodhound.tokenizers.whitespace(d.search_value)
    queryTokenizer: Bloodhound.tokenizers.whitespace
    
  });

  initComplete = song_engine.initialize()
  initComplete = gig_engine.initialize()
  initComplete = venue_engine.initialize()
  initComplete = composition_engine.initialize()
  initComplete = performance_engine.initialize()

  init = () -> 

    $(".typeahead").typeahead({
      hint: true,
      highlight: true,
      minLength: 1
    },

    {
      name: 'songs',
      displayKey: 'search_value',
      source: song_engine.ttAdapter(),
      templates: {
        header: '<h4 class="">Songs</h4>'
      }
    },

    {
      name: 'compositions',
      displayKey: 'search_value',
      source: composition_engine.ttAdapter(),
      templates: {
        header: '<h4 class="">Albums</h4>'
      }
    },

    {
      name: 'gigs',
      displayKey: 'search_value',
      source: gig_engine.ttAdapter(),
      templates: {
        header: '<h4 class="">Gigs</h4>'
      }
    },

    {
      name: 'venues',
      displayKey: 'search_value',
      source: venue_engine.ttAdapter(),
      templates: {
        header: '<h4 class="">Venues</h4>'
      }
    },

    {
      name: 'performances',
      displayKey: 'search_value',
      source: performance_engine.ttAdapter(),
      templates: {
        header: '<h4 class="">Performances</h4>'
      }
    })


    $(".typeahead").bind("typeahead:selected", (event, suggestion, dataset) ->
      console.log("dataset: " + dataset + "; selected: " + suggestion.search_value, " - " + suggestion.id)

      switch dataset
        when "songs" then window.location = "/songs/" + suggestion.id
        when "gigs" then window.location = "/gigs/" + suggestion.id
        when "venues" then window.location = "/venues/" + suggestion.id
        when "compositions" then window.location = "/compositions/" + suggestion.id
        when "performances" then window.location = "/performances/" + suggestion.id

    )

    $("#search_value").focus()  


  initComplete.then(init)

)