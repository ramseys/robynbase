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
  

 
states = ['Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California',
  'Colorado', 'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii',
  'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
  'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
  'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire',
  'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota',
  'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island',
  'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont',
  'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming'
]


$(window).on("load", -> 

  currentPage = window.location.pathname.substring(1);

  activeTab = switch
    when currentPage == "" then "robyn-home"
    when currentPage == "songs" then "robyn-songs"
    else "home"

  $("##{activeTab}").addClass("active")

  $("#search_value").on("keypress", (e) ->

    if e.which == 10 or e.which == 13
      $("#main-search").submit();

  )

  $(".main-search-list tr").on("click", (e) ->
    window.location = $(e.currentTarget).data("path")
  )

  statesEngine = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('search_value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    # `states` is an array of state names defined in "The Basics"
    local: $.map(states, (state) -> 
      return { search_value: state }
    )
  });

  # initComplete = statesEngine.initialize()
   

  engine = new Bloodhound({
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

  initComplete = engine.initialize()
  initComplete = gig_engine.initialize()
  initComplete = composition_engine.initialize()

  init = () -> 

    $(".typeahead").typeahead({
      hint: true,
      highlight: true,
      minLength: 1
    },

    {
      name: 'songs',
      displayKey: 'search_value',
      source: engine.ttAdapter(),
      templates: {
        header: '<h4 class="">Songs</h3>'
      }
    },

    {
      name: 'compositions',
      displayKey: 'search_value',
      source: composition_engine.ttAdapter(),
      templates: {
        header: '<h4 class="">Albums</h3>'
      }
    },

    {
      name: 'gigs',
      displayKey: 'search_value',
      source: gig_engine.ttAdapter(),
      templates: {
        header: '<h4 class="">Gigs</h4>'
      }
    })


    $(".typeahead").bind("typeahead:selected", (event, suggestion, dataset) ->
      console.log("dataset: " + dataset + "; selected: " + suggestion.search_value, " - " + suggestion.id)

      switch dataset
        when "songs" then window.location = "/songs/" + suggestion.id
        when "gigs" then window.location = "/gigs/" + suggestion.id
        when "compositions" then window.location = "/compositions/" + suggestion.id

    )

    $("#search_value").focus()  


  initComplete.then(init)

)