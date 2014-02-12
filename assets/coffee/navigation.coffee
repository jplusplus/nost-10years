# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : n-host : Map for the 10th anniversary of the EU-enlargement
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 27-Jan-2014
# Last mod : 07-Feb-2014
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
		for story of settings.stories
			q.defer d3.csv,  "static/data/#{story}-infos.csv"
			q.defer d3.csv,  "static/data/#{story}-data.csv", (d) ->
				d.serie1 = parseFloat d.serie1
				d.serie2 = parseFloat d.serie2
				return d
		q.awaitAll(@loadedDataCallback)

	loadedDataCallback: (error, results) =>
		# get map data
		map          = results[0]
		geo_features = topojson.feature(map, map.objects.admin0).features
		# get stories
		@stories = d3.map()
		results  = results.slice(1) # remove the map
		for o, i in Array(results.length/2) # read the array 2 by 2 (infos and data)
			infos     = results[i + i][ 0]
			data      = results[i + i + 1]
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
		@map    = new Map(this  , geo_features, @stories)
		@panel  = new Panel(this, @stories)
		@banner = new Banner(this)

	selectStory: (story) =>
		@selected_story = story
		$(document).trigger("storySelected", story)

# EOF
