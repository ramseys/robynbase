# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(window).on("load", (e) ->
  $("a.album-art").attr("rel", "gallery").fancybox({helpers : { 
    thumbs : {
      width  : 50,
      height : 50
    }
  }})
)