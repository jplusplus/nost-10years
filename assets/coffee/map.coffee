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

# NOTE: List all the stories
# key should be the prefix of the story file in static/data
# you can provide some properties like:
#	center : [lon, lat]
#	zoom   : int (normal=1)
STORIES = { 
	"project-1"
	"project-2" :
		center : [19.020662, 42.583409]
		zoom   : 2
	"project-3"
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
		nui.find("span.title")  .html(story.infos['Title of the tab'])
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
		initial_center : [10, 49]

	constructor: (navigation, map, stories) ->
		@story_selected = undefined
		@navigation     = navigation
		@map            = map
		@stories        = stories

		@uis =
			switch_button : $(".switch", ".map")

		@relayout()

		#bind events
		$(document).on("storySelected", @onStorySelected)
		@uis.switch_button.find("input.switch-input").on("change", @onSwitchButtonChange)
		$(window).resize(@relayout)

	relayout: =>
		# Create svg tag
		@width  = $(window).width() - $(".map").offset().left
		@height = $(window).height()
		d3.select(".map svg").remove()
		@svg = d3.select(".map")
			.insert("svg" , ":first-child")
			.attr("width" , @width)
			.attr("height", @height)

		# Create projection
		@projection = d3.geo.mercator()
			.center(CONFIG.initial_center)
			.scale(@width * .7)
			.translate([@width/2, @height/2])

		# Create the path
		@path  = d3.geo.path().projection(@projection)
		@group = @svg.append("g")
		# Create the group of path and add graticule
		@groupPaths = @group.append("g").attr("class", "all-path")
		@drawEuropeMap()
		# draw the map if a story is selected
		@drawMap(@story_selected) if @story_selected?

	onStorySelected : (e, story_key) =>
		@story_selected = story_key
		@drawMap(story_key)
		infos = @stories[@story_selected].infos
		if infos.Serie1? and infos.Serie2?
			@uis.switch_button.find("label[for=serie1]").text(infos.Serie1)
			@uis.switch_button.find("label[for=serie2]").text(infos.Serie2)
			@uis.switch_button.find("label[for=serie2]").text(infos.Serie2)
			@uis.switch_button.find("input.switch-input:checked").prop("checked", false)
			@uis.switch_button.find("input.switch-input:first").prop("checked", true)
			@uis.switch_button.removeClass("hidden")
		else
			@uis.switch_button.addClass("hidden")

	onSwitchButtonChange: (e) =>
		value = @uis.switch_button.find("input.switch-input:checked").val()
		serie  = parseInt(value.replace("serie", ""))
		@drawChoroplethMap(serie)

	drawMap: (story_key) =>
		story  = @stories[@story_selected]
		symbol = story.infos["Symbol map (Yes or No). If No, it's a Choropleth maps"] == "Yes"
		if symbol
			@drawSymbolMap()
		else
			@drawChoroplethMap(1)

	drawChoroplethMap: (serie=1) =>
		countries = {}
		for line in @stories[@story_selected].data
			if line['Country ISO Code']? and line['Country ISO Code'] != ""
				# cast
				line["value"] = parseFloat(line["serie#{serie}"]) or undefined
				countries[line['Country ISO Code']] = line
		values = _.values(countries).map((d)->d["value"]).filter((d) -> d?)
		domain = [Math.min.apply(Math, values), Math.max.apply(Math, values)]
		scale  = chroma.scale("YlOrRd").domain(domain, 5)
		# tooltip
		@groupPaths.selectAll('path').each (d) ->
			data  = countries[d.properties.iso_a3]
			value = ""
			if data?
				value = data["value"] or ""
			country_name = if data? then data["Country name"] else ""
			append       = if data? then data["Append Sign (€,%, Mio, etc)"] or "" else ""
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
		zoom      = STORIES[@story_selected].zoom or 1
		center    = @projection(STORIES[@story_selected].center)
		offset_x  = - (center[0] * zoom - @width / 2)
		offset_y  = - (center[1] * zoom - @height / 2)
		@groupPaths.selectAll('path')
			.attr('fill', (d) -> d3.select(this).attr("fill") or "white")
			.transition()
				.duration(2000)
				.attr("transform", "translate(#{offset_x},#{offset_y})scale(#{zoom})")
				.attr 'fill', (d) -> # color countries using the color scale
					country = countries[d.properties.iso_a3]
					if country?
						value = countries[d.properties.iso_a3]["value"]
						if value? then scale(value) else undefined
					else
						"white"

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
