# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : n-host : Map for the 10th anniversary of the EU-enlargement
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 27-Jan-2014
# Last mod : 03-Feb-2014
# -----------------------------------------------------------------------------

STORIES = {
	"project-1"
	"project-2" :
		center : [-300,-240]
		zoom   : 2
}

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
		for story of STORIES
			q.defer(d3.csv,  "static/data/#{story}-infos.csv")
			q.defer(d3.csv,  "static/data/#{story}-data.csv")
		q.awaitAll(@loadedDataCallback)

	loadedDataCallback: (error, results) =>
		# get map data
		map          = results[0]
		geo_features = topojson.feature(map, map.objects.admin0).features
		# get stories
		@stories = {}
		results  = results.slice(1) # remove the map
		for o, i in Array(results.length/2) # read the array 2 by 2 (infos and data)
			infos     = results[i + i][ 0]
			data      = results[i + i + 1]
			story_id  = _.keys(STORIES)[i]

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
		hidden      = false
		@ui         = $(".banner")
		@uis =
			title       : $("> .title"      , @ui)
			description : $("> .description", @ui)
			increase    : $("> .increase"   , @ui)
			reduce      : $("> .reduce"     , @ui)

		#bind events
		$(document).on("storySelected", @onStorySelected)
		@ui        .on("click", => if @hidden then @show() else @hide())

		# init hide/show button
		if @hidden then @hide() else @show()

	update: (title, description) =>
		@uis.title      .html(title)
		@uis.description.html(description)

	onStorySelected: (e, story_key) =>
		title       = @navigation.stories[story_key].infos['Title']
		description = @navigation.stories[story_key].infos['Introduction']
		@update(title, description)
		@show()

	hide: =>
		@hidden = true
		@ui.addClass("reduced")
		@uis.reduce.addClass("hidden")
		@uis.increase.removeClass("hidden")

	show: =>
		@hidden = false
		@ui.removeClass("reduced")
		@uis.increase.addClass("hidden")
		@uis.reduce.removeClass("hidden")

# -----------------------------------------------------------------------------
#
#    Europe MAP
#
# -----------------------------------------------------------------------------
class Map

	# Define default config
	CONFIG =
		initial_zoom   : 500
		initial_center : [10, 53]

	constructor: (navigation, map, stories) ->
		@navigation = navigation
		@map        = map
		@stories    = stories

		@relayout()

		#bind events
		$(document).on("storySelected", @onStorySelected)
		$(window).resize(@relayout)

	relayout: =>
		# Create svg tag
		@width  = $(window).width() - $(".map").offset().left
		@height = $(window).height()
		d3.select(".map svg").remove()
		@svg = d3.select(".map")
			.insert("svg" , ":first-child")
			.attr("width" , @width)
			.attr("height",@height)

		# Create projection
		@projection = d3.geo.mercator()
			.center(CONFIG.initial_center)
			.scale(CONFIG.initial_zoom)
			.translate([@width/2, @height/2])

		# Create the path
		@path  = d3.geo.path().projection(@projection)
		@group = @svg.append("g")
		# Create the group of path and add graticule
		@groupPaths = @group.append("g").attr("class", "all-path")
		@drawEuropeMap()

	onStorySelected: (e, story_key) =>
		@story = @stories[story_key]
		symbol = @story.infos["Symbol map (Yes or No). If No, it's a Choropleth maps"] == "Yes"
		if symbol
			@drawSymbolMap()
		else
			@drawChoroplethMap("2003", STORIES[story_key].center, STORIES[story_key].zoom)

	drawChoroplethMap: (serie="2003", center, zoom) =>
		countries = {}
		for line in @story.data
			if line['Country ISO Code']? and line['Country ISO Code'] != ""
				# cast
				line[serie] = parseFloat(line[serie]) or undefined
				countries[line['Country ISO Code']] = line
		values = _.values(countries).map((d)->d[serie]).filter((d) -> d?)
		domain = [Math.min.apply(Math, values), Math.max.apply(Math, values)]
		scale  = chroma.scale(['white', 'red']).domain(domain)
		# tooltip 
		@groupPaths.selectAll('path').each (d) ->
			data  = countries[d.properties.iso_a3]
			value = ""
			if data?
				value = data[serie] or ""
			country_name = if data? then data["Country name"] else ""
			append       = if data? then data["Append Sign (€,%, Mio, etc)"] else ""
			if country_name
				$(this).qtip
					content: "#{country_name}<br/><strong>#{value} #{append}</strong>"
					style:
						theme: 'qtip-dark'
						tip:
							corner: false
					position:
						target: 'mouse'
						adjust:
							x: 10
							y: -20
		# zoom + move + color animation
		zoom      = zoom or 1
		center    = center or [0,0]
		@groupPaths.selectAll('path')
			.attr('fill', 'white')
			.transition()
				.duration(2000)
				.attr("transform", "scale(#{zoom})translate(#{center[0]},#{center[1]})")
				.attr 'fill', (d) -> # color countries using the color scale
					country = countries[d.properties.iso_a3]
					if country?
						value = countries[d.properties.iso_a3][serie]
						if value? then scale(value) else undefined
					else
						"#E5E5E5"

	# zoom: (_scale, _center) =>
	# 	return (timestamp) =>
	# 		if not @start?
	# 			@start = timestamp
	# 		progress = timestamp - @start
	# 		scale = @projection.scale()
	# 		scale += (2 - scale) * progress/1000
	# 		center = @projection.center()
	# 		center[0] += (_center[0] - center[0]) * progress/1000
	# 		center[1] += (_center[1] - center[1]) * progress/1000
	# 		@groupPaths.attr("transform", "scale("+scale+")")
	# 		# @projection
	# 		# 	.scale(scale)
	# 		# 	.center(center)
	# 		# @groupPaths.selectAll('path').attr("d", @path)
	# 		if progress < 1000
	# 			requestAnimationFrame @zoom(_scale, _center)

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
