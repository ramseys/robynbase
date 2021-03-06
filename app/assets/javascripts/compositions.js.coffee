# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(window).on("load", (e) ->

  # set up album art lightbox
  $("a.album-art").attr("rel", "gallery").fancybox({helpers : { 
    thumbs : {
      width  : 50,
      height : 50
    }
  }})

  # hide/show album blocks
  $(".album-block-header").on("click", (e) -> 
    albumHeader = $(e.target).parents(".album-block-header");
    albumBlock = $(".album-block-container[data-compid=" + albumHeader.data("compid") + "]")
    albumBlock.toggle()
    albumHeader.find(".glyphicon").toggleClass("glyphicon-triangle-right glyphicon-triangle-bottom")
  )

  # hide show advanced options in list page
  $(".album-list .advanced-options-header").on("click", (e) ->
    header = $(e.target).parents(".advanced-options-header")
    criteriaBlock = header.next();
    criteriaBlock.toggleClass("expanded");
    header.find(".glyphicon").toggleClass("glyphicon-triangle-right glyphicon-triangle-bottom")
  )

)
