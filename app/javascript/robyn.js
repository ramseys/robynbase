// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

// const substringMatcher = strs => (function(q, cb) {

//   // an array that will be populated with substring matches
//   const matches = [];

//   // regex used to determine if a string contains the substring `q`
//   const substrRegex = new RegExp(q, 'i');

//   // iterate through the pool of strings and for any string that
//   // contains the substring `q`, add it to the `matches` array
//   $.each(strs, function(i, str) {
//     if (substrRegex.test(str)) {
//       // the typeahead jQuery plugin expects suggestions to a
//       // JavaScript object, refer to typeahead docs for more info
//       return matches.push({ search_value: str });
//     }
    
//   });

//   return cb(matches);

// });

// Clean up typeahead instances before page transitions
$(document).on("turbo:before-cache", function() {
  if ($(".typeahead").length > 0) {
    $(".typeahead").typeahead('destroy');
  }
});

$(window).on("turbo:load", function() { 

  const currentPage = window.location.pathname.substring(1);

  const activeTab = (() => { switch (false) {
    case currentPage !== "": return "robyn-home";
    case currentPage.indexOf("songs") !== 0: return "robyn-songs";
    case currentPage.indexOf("compositions") !== 0: return "robyn-compositions";
    case currentPage.indexOf("gigs") !== 0: return "robyn-gigs";
    case currentPage.indexOf("venues") !== 0: return "robyn-venues";
    case currentPage.indexOf("map") !== 0: return "venue-map";
    case currentPage.indexOf("about") !== 0: return "robyn-about";
    default: return "robyn-home";
  } })();

  $(`#${activeTab}`).addClass("active");

  $("#search_value").on("keypress", function(e) {

    if ((e.which === 10) || (e.which === 13)) {
      return $("#main-search").submit();
    }

  });

  // set all hrefs in notes/comments sections to open in a new tab/window
  $(".notes-section a").each((index, anchor) => {
    $(anchor).attr("target", "_blank");
  });

  // show overlays when hovering over images / image galleries
  $(".image-box")
    .on("mouseenter", (e) => { $(e.currentTarget).addClass("overlay")})
    .on("mouseleave", (e) => { $(e.currentTarget).removeClass("overlay")});
   
  // add lightbox for any image galleries
  $().fancybox({
    selector : 'a.image-gallery',
    loop: true
  });

  const song_engine = new Bloodhound({
    // name: 'all'
    // local: [{ val: 'dog' }, { val: 'pig' }, { val: 'moose' }],
    remote: {
      url: '/robyn/search?utf8=%E2%9C%93&search_value=%QUERY',
      filter(results) {
        return $.map(results, function(result, index) {
          const prefix = result.Prefix ? (result.Prefix + " ") : "";
          return {search_value: prefix + result.Song, id: result.SONGID};
        });
      }
    },
    datumTokenizer(d) { 
      console.log(d);
      return Bloodhound.tokenizers.whitespace(d.search_value);
    },

    queryTokenizer: Bloodhound.tokenizers.whitespace
    
  });
  
  const gig_engine = new Bloodhound({
    // name: 'all'
    // local: [{ val: 'dog' }, { val: 'pig' }, { val: 'moose' }],
    remote: {
      url: '/robyn/search_gigs?utf8=%E2%9C%93&search_value=%QUERY',
      filter(results) {
        return $.map(results, (result, index) => ({
          search_value: result.Venue,
          id: result.GIGID
        }));
      }
    },
    datumTokenizer(d) { 
      console.log(d);
      return Bloodhound.tokenizers.whitespace(d.search_value);
    },
    queryTokenizer: Bloodhound.tokenizers.whitespace
    
  });

  const composition_engine = new Bloodhound({
    // name: 'all'
    // local: [{ val: 'dog' }, { val: 'pig' }, { val: 'moose' }],
    remote: {
      url: '/robyn/search_compositions?utf8=%E2%9C%93&search_value=%QUERY',
      filter(results) {
        return $.map(results, (result, index) => ({
          search_value: result.Title,
          id: result.COMPID
        }));
      }
    },
    datumTokenizer(d) { 
      console.log(d);
      return Bloodhound.tokenizers.whitespace(d.search_value);
    },
    queryTokenizer: Bloodhound.tokenizers.whitespace
    
  });

  const venue_engine = new Bloodhound({
    // name: 'all'
    // local: [{ val: 'dog' }, { val: 'pig' }, { val: 'moose' }],
    remote: {
      url: '/robyn/search_venues?utf8=%E2%9C%93&search_value=%QUERY',
      filter(results) {
        return $.map(results, (result, index) => ({
          search_value: result.Name,
          id: result.VENUEID
        }));
      }
    },
    datumTokenizer(d) { 
      console.log(d);
      return Bloodhound.tokenizers.whitespace(d.search_value);
    },
    queryTokenizer: Bloodhound.tokenizers.whitespace
    
  });


  let initComplete = song_engine.initialize();
  initComplete = gig_engine.initialize();
  initComplete = venue_engine.initialize();
  initComplete = composition_engine.initialize();

  const init = function() { 

    // Ensure any existing typeahead instances are destroyed first
    if ($(".typeahead").length > 0 && $(".typeahead").data('ttTypeahead')) {
      $(".typeahead").typeahead('destroy');
    }

    // $(".typeahead").typeahead({
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
        header: '<h4 class="">Releases</h4>'
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
    });


    $(".typeahead").bind("typeahead:selected", function(event, suggestion, dataset) {
      console.log("dataset: " + dataset + "; selected: " + suggestion.search_value, " - " + suggestion.id);

      switch (dataset) {
        case "songs": return window.location = "/songs/" + suggestion.id;
        case "gigs": return window.location = "/gigs/" + suggestion.id;
        case "venues": return window.location = "/venues/" + suggestion.id;
        case "compositions": return window.location = "/compositions/" + suggestion.id;
      }
    });

    $("#search_value").focus();  

  };

  initComplete.then(init);

});