# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).on "click", "#show_duration", (e)->
	event.preventDefault()
	window.location.href = "/?duration=" + $('#duration').val() + "days"

$(document).on "click", "#download", (e)->
	event.preventDefault()
	window.location.href = "https://blockchain.info/charts/market-price?showDataPoints=false&timespan=" + $('#duration').val() + "days&show_header=true&daysAverageString=1&scale=0&format=csv&address="

$(document).on "click", "#timeseries_menu", (e)->
	event.preventDefault()
	$("html,body").animate({scrollTop:$('#timeseries').offset().top})

$(document).on "click", "#stats_menu", (e)->
  event.preventDefault()
  $("html,body").animate({scrollTop:$('#stats').offset().top})

$(document).on "click", "#bep_menu", (e)->
  event.preventDefault()
  $("html,body").animate({scrollTop:$('#bep').offset().top})

$(document).on "click", "#raw_data_menu", (e)->
  event.preventDefault()
	$("html,body").animate({scrollTop:$('#raw_data').offset().top})
