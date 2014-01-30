# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : n-host : Map for the 10th anniversary of the EU-enlargement
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 27-Jan-2014
# Last mod : 30-Jan-2014
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
#
#    NAVIGATION
#
# -----------------------------------------------------------------------------
class Navigation

	CONFIG =
		urls :
			map  : "static/europe.topo.json"

	constructor: ->

	start: =>
		queue()
			.defer(d3.json, CONFIG.urls.map)
			.await(@loadedDataCallback)

	loadedDataCallback: (error, map, tour, overview) =>
		geo_features = topojson.feature(map, map.objects.europe).features
		@map         = new Map(this, geo_features)
		@panel       = new Panel(this)

# -----------------------------------------------------------------------------
#
#    PANEL
#
# -----------------------------------------------------------------------------
class Panel

	constructor: (navigation) ->
		@navigation = navigation


# -----------------------------------------------------------------------------
#
#    Europe MAP
#
# -----------------------------------------------------------------------------
class Map

	# Define default config
	CONFIG =
		svg_height                 : 500
		svg_width                  : 600
		initial_zoom               : 400
		initial_center             : [30, 55]

	constructor: (navigation, map, stories) ->
		@navigation = navigation
		@map        = map
		@stories    = stories

		# Create svg tag
		@svg = d3.select(".map")
			.insert("svg", ":first-child")
			.attr("width", CONFIG.svg_width)
			.attr("height", CONFIG.svg_height)

		# Create projection
		@projection = d3.geo.mercator()
			.center(CONFIG.initial_center)
			.scale(CONFIG.initial_zoom)
			.translate([CONFIG.svg_width/2, CONFIG.svg_height/2])

		# Create the path
		@path = d3.geo.path()
			.projection(@projection)

		@group = @svg.append("g")

		# Create the group of path and add graticule
		@groupPaths = @group.append("g")
			.attr("class", "all-path")

		@drawEuropeMap()

	drawEuropeMap: =>
		# Create every countries
		@groupPaths.selectAll("path")
			.data(@map)
			.enter()
				.append("path")
				.attr("d", @path)

# -----------------------------------------------------------------------------
#
#    MAIN
#
# -----------------------------------------------------------------------------
navigation = new Navigation()
navigation.start()

# EOF
