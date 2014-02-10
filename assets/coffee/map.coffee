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
		initial_zoom   : 530
		initial_center : [24.247769, 50.117286]
		new_countries  : ["BGR","EST","LVA","LTU","POL","ROU","SVK","SVN","CZE","HUN"] # large border


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
		@drawChoroplethMap(serie)

	drawMap: (story_key) =>
		story  = @stories.get(@story_selected)
		symbol = story.infos["Symbol map (Yes or No). If No, it's a Choropleth maps"].toLowerCase() == "yes"
		if symbol
			@drawSymbolMap()
		else
			@drawChoroplethMap()

	drawChoroplethMap: (serie=1) =>
		countries = @stories.get(@story_selected).data
		# scale
		values = countries.values().map((d)->d["serie#{serie}"]).filter((d) -> d? and not isNaN(d))
		domain = [Math.min.apply(Math, values), Math.max.apply(Math, values)]
		scale  = chroma.scale("YlOrRd").domain(domain, 5, STORIES[@story_selected]['scale_type'])
		# tooltip
		@groupPaths.selectAll('path').each @tooltip
		# zoom + move + color animation
		zoom      = STORIES[@story_selected].zoom or 1
		center    = @projection(STORIES[@story_selected].center or CONFIG.initial_center)
		offset_x  = - (center[0] * zoom - @width / 2)
		offset_y  = - (center[1] * zoom - @height / 2)
		@groupPaths.selectAll('path')
			.attr 'fill', (d) ->
				# star or unstar country
				country = countries.get(d.properties.iso_a3)
				if country
					d3.select(this).classed("discret", country["starred_country(y/n)"] == "no")
				# init color before transition
				d3.select(this).attr("fill") or "white"
			.transition()
				.duration(1000)
				.attr 'fill', (d) -> # color countries using the color scale
					country = countries.get(d.properties.iso_a3)
					if country?
						# colorize country
						value = country["serie#{serie}"]
						color =  if value? then scale(value).hex() else undefined
					else
						color = "white"
					d.color = color
					return color
				.attr("stroke", (d) -> chroma(d.color).darker()) # border color
				.attr("transform", "translate(#{offset_x},#{offset_y})scale(#{zoom})")

	drawSymbolMap: (serie=1) =>


	drawEuropeMap: =>
		# Create every countries
		@groupPaths.selectAll("path")
			.data(@map)
			.enter()
				.append("path")
				.attr("d", @path)
				.classed "new-eu-country", (d) -> d.properties.iso_a3 in CONFIG.new_countries

	tooltip: (d) =>
		data  = @stories.get(@story_selected).data[d.properties.iso_a3]
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

# EOF
