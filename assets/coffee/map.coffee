# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : n-host : Map for the 10th anniversary of the EU-enlargement
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 27-Jan-2014
# Last mod : 10-Feb-2014
# -----------------------------------------------------------------------------
#
#    Europe MAP
#
# -----------------------------------------------------------------------------
class Map

	# Define default config
	CONFIG =
		map_transition    : 1000
		initial_center    : [24.247769, 50.117286]
		symbol_scale      : [20, 60]
		map_default_color : "#D6D6D6"
		color_scale       : "YlOrRd" # http://colrd.com/palette/19079/
		new_countries     : ["BGR","EST","LVA","LTU","POL","ROU","SVK","SVN","CZE","HUN"] # for larger border

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
		@groupPaths   = @group.append("g").attr("class", "all-path")
		@groupSymbols = @groupPaths.append("g").attr("class", "all-symbols")
		@drawEuropeMap()
		# draw the map if a story is selected
		@drawMap(@story_selected) if @story_selected?

	onStorySelected : (e, story_key) =>
		@story_selected = story_key
		@drawMap(story_key)
		infos = @stories.get(@story_selected).infos
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
		@drawMap(@story_selected, serie)

	drawMap: (story_key, serie=1) =>
		# reset tooltip
		@destroyTooltip()
		story  = @stories.get(@story_selected)
		# select the right method
		if story.infos.is_symbol
			@drawSymbolMap(serie)
		else
			@groupSymbols.selectAll("image").remove()
			@drawChoroplethMap(serie)

	drawChoroplethMap: (serie=1) =>
		countries = @stories.get(@story_selected).data
		# scale
		values = countries.values().map((d)->d["serie#{serie}"]).filter((d) -> d? and not isNaN(d))
		domain = [Math.min.apply(Math, values), Math.max.apply(Math, values)]
		scale  = chroma.scale(CONFIG.color_scale).domain(domain, 5, STORIES[@story_selected]['scale_type'])
		 # zoom + move + color animation
		@groupPaths.selectAll('path')
			.attr 'fill', (d) ->
				# star or unstar country
				country = countries.get(d.properties.iso_a3)
				if country
					d3.select(this).classed("discret", country["starred_country(y/n)"] == "no")
				# init color before transition
				d3.select(this).attr("fill") or CONFIG.map_default_color
			.transition()
				.duration(CONFIG.map_transition)
				.attr 'fill', (d) -> # color countries using the color scale
					country = countries.get(d.properties.iso_a3)
					if country?
						# colorize country
						value = country["serie#{serie}"]
						color =  if value? then scale(value).hex() else undefined
					else
						color = CONFIG.map_default_color
					d.color = color
					return color
				.attr("stroke", (d) -> chroma(d.color).darker()) # border color
				# zoom + move
				.attr("transform", @computeZoom(@story_selected))
		# tooltip
		@groupPaths.selectAll('path').each @tooltip(serie=serie)

	drawSymbolMap: (serie=1) =>
		that      = this
		story     = @stories.get(@story_selected)
		countries = story.data.values()
		# keep only row with value to show
		countries = countries.filter (c) ->
			c["serie1"]? and not isNaN(c["serie1"]) and c["serie2"]? and not isNaN(c["serie2"])
		# scale
		values = []
		for country in countries
			values.push(country["serie1"])
			values.push(country["serie2"])
		scale  = d3.scale.linear()
			.domain([Math.min.apply(Math, values), Math.max.apply(Math, values)])
			.range(CONFIG.symbol_scale)
		@groupPaths.selectAll('path')
			.attr 'fill', (d) ->
				# init color before transition
				d3.select(this).attr("fill") or CONFIG.map_default_color
			.transition()
				.duration(CONFIG.map_transition)
				.attr 'fill', (d) ->
					color   = CONFIG.map_default_color
					d.color = color
				.attr("stroke"   , (d) -> chroma(d.color).darker()) # border color
				.attr("transform", @drawEuropeMap(@story_selected))

		#  init symbols
		@groupSymbols.selectAll("image")
			.data(countries).enter()
			.append("image", ".all-symbols")
				.classed("discret", (d) -> d["starred_country(y/n)"] == "no")
				.attr("xlink:href" , (d) -> return "static/symbols/smiley.png")
				.attr("width"      , (d) -> 0)
				.attr("height"     , (d) -> 0)
				.attr("x"          , (d) => @path.centroid(@map.filter((f) -> f.properties["iso_a3"] == d["Country ISO Code"])[0])[0]  - scale(d["serie#{serie}"])/2)
				.attr("y"          , (d) => @path.centroid(@map.filter((f) -> f.properties["iso_a3"] == d["Country ISO Code"])[0])[1]  - scale(d["serie#{serie}"])/2)
				.attr("opacity"    , 0)

		# redraw
		@groupSymbols.selectAll("image")
			.transition()
				.duration(CONFIG.map_transition)
				.attr("opacity", 1)
				.attr("width"  , (d) -> scale(d["serie#{serie}"]))
				.attr("height" , (d) -> scale(d["serie#{serie}"]))

		# tooltip
		@groupSymbols.selectAll("image").each @tooltip(serie=serie)

	drawEuropeMap: =>
		### Create every countries ###
		@groupPaths.selectAll("path")
			.data(@map)
			.enter()
				.insert("path", ".all-symbols")
				.attr("d", @path)
				.classed "new-eu-country", (d) -> d.properties.iso_a3 in CONFIG.new_countries

	computeZoom: (story) =>
		### Return the translation instruction as string ex: "translate(1,2)scale(1)"" ###
		zoom      = STORIES[story].zoom or 1
		center    = @projection(STORIES[story].center or CONFIG.initial_center)
		offset_x  = - (center[0] * zoom - @width  / 2)
		offset_y  = - (center[1] * zoom - @height / 2)
		return "translate(#{offset_x},#{offset_y})scale(#{zoom})"

	destroyTooltip: =>
		### Destroy all the tooltips ###
		$("image").qtip('destroy', true)
		$("path") .qtip('destroy', true)

	tooltip: (serie) =>
		### use the @story_selected to create tooltip depending of the given serie ###
		that = this
		return (d) ->
			# retrieve data, depending of the element type (feature or symbol)
			data  = if d.properties? then that.stories.get(that.story_selected).data.get(d.properties.iso_a3) else d
			country_name = if data? then data["Country name"]                      else ""
			value        = if data? then data["serie#{serie}"]               or "" else ""
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

# EOF
