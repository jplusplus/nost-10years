# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : n-host : Map for the 10th anniversary of the EU-enlargement
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 27-Jan-2014
# Last mod : 25-Feb-2014
# -----------------------------------------------------------------------------
#
#    NAVIGATION
#
# -----------------------------------------------------------------------------
class Navigation

	constructor: ->
		@stories = undefined
		# widget
		@map     = undefined
		@panel   = undefined
		@banner  = undefined

	start: =>
		q = queue()
		q.defer(d3.json, "static/europe.topo.json")
		q.defer(d3.csv, "static/join.csv")
		for story of settings.stories
			q.defer d3.csv,  "static/projects/#{story}_Infos.csv"
			q.defer d3.csv,  "static/projects/#{story}_Data.csv", (d) ->
				d.serie1 = parseFloat d.serie1
				d.serie2 = parseFloat d.serie2
				return d
		q.awaitAll(@loadedDataCallback)

	loadedDataCallback: (error, results) =>
		# (1) get map data
		map          = results[0]
		geo_features = topojson.feature(map, map.objects.admin0).features
		# (2) get main map data
		accessions = d3.map()
		accessions.set(line["Country ISO Code"], line) for line in results[1]
		# (3) get stories
		@stories = d3.map()
		results  = results.slice(2) # remove the map (1) and the main data (2)
		for o, i in Array(results.length/2) # read the array 2 by 2 (infos and data)
			infos     = results[i * 2][ 0]
			data      = results[i * 2 + 1]
			# data
			infos.is_symbol = infos["Symbol map (Yes or No). If No, it's a Choropleth maps"].toLowerCase() == "yes"
			# series
			series = d3.map()
			series.set(line["Country ISO Code"], line) for line in data
			# save stories
			story_id  = _.keys(settings.stories)[i]
			@stories.set story_id,
				infos  : infos
				data   : series
		# instanciate widgets
		@map    = new Map(this  , geo_features, accessions, @stories)
		@panel  = new Panel(this, @stories)
		@banner = new Banner(this)
		# init map from url
		@readHash()
		# remove the loading class
		setTimeout(-> 
			$("body").removeClass("loading")
		, 500)
		# bind events
		$(window).on('hashchange', @readHash)

	selectStory: (story) =>
		@selected_story = story
		window.location.hash = story
		$(document).trigger("storySelected", story)

	readHash: (e) =>
		story = window.location.hash.slice(1)
		@selectStory(story) if @stories.get(story)?

# EOF
