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

STORIES = [
	"project-1"
	"project-2"
]

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
		for story in STORIES
			q.defer(d3.dsv(";", "text/plain"),  "static/data/#{story}-infos.csv")
			q.defer(d3.dsv(";", "text/plain"),  "static/data/#{story}-data.csv")
		q.awaitAll(@loadedDataCallback)

	loadedDataCallback: (error, results) =>
		# get map data
		map          = results[0]
		geo_features = topojson.feature(map, map.objects.europe).features
		# get stories
		@stories = {}
		results = results.slice(1) # remove the map
		for _, i in Array(results.length/2) # read the array 2 by 2 (infos and data)
			infos     = results[i + i][ 0]
			data      = results[i + i + 1]
			story_id  = STORIES[i]
			@stories[story_id] =
				infos : infos
				data  : data

		# instanciate widgets
		@map    = new Map(this  , geo_features, @stories)
		@panel  = new Panel(this, @stories)
		@banner = new Banner(this)

	selectStory: (story) =>
		@selected_story = story
		$(document).trigger("storySelected", story)

# -----------------------------------------------------------------------------
#
#    PANEL
#
# -----------------------------------------------------------------------------
class Panel

	constructor: (navigation, stories) ->
		@navigation = navigation
		@stories    = stories
		@uis = 
			panel     : $(".panel.stories")
			story_tmpl: $(".story.template", ".panel.stories")

		# init the panel
		@setStories(stories)

		#bind events
		$(document).on("storySelected", @onStorySelected)

	selectStories: => $(".story:not(.template)", @uis.panel)

	setStories: (stories) =>
		### reset the stories list ###
		@selectStories().remove() # remove previous stories
		for key, values of stories
			nui = @createStory(key, values)
			@uis.panel.append(nui) # add to DOM
		# bind events
		@selectStories().on "click", (e) =>
			story_key = $(e.currentTarget).data('id')
			@navigation.selectStory(story_key)

	createStory: (key, story) =>
		### Clone from a template a story item and fill out the field ###
		nui = @uis.story_tmpl.clone().removeClass("template")
		nui.find(".title")      .html(story.infos['Title of the tab'])
		nui.find(".description").html(story.infos['Title'])
		nui.data("id", key)
		return nui

	onStorySelected: (e, story) =>
		@selectStories().each (i, nui) ->
			$(nui).toggleClass("active", $(nui).data('id') == story)

# -----------------------------------------------------------------------------
#
#    BANNER
#
# -----------------------------------------------------------------------------
class Banner

	constructor: (navigation) ->
		@navigation = navigation
		@uis =
			title : $("> .title", ".banner")

	setTitle: (title) =>
		@uis.title.html(title)

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
