# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : n-host : Map for the 10th anniversary of the EU-enlargement
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 27-Jan-2014
# Last mod : 11-Feb-2014
# -----------------------------------------------------------------------------
#
#    Europe MAP
#
# -----------------------------------------------------------------------------
class Map

	# Define default settings.Map
	CONFIG =
		map_transition    : 1000
		initial_center    : [24.247769, 50.117286]
		symbol_scale      : [20, 60]
		map_default_color : "#D6D6D6"
		color_scale       : "YlOrRd" # http://colrd.com/palette/19079/
		new_countries     : ["BGR","EST","LVA","LTU","POL","ROU","SVK","SVN","CZE","HUN"] # for larger border
		countries_centers : d3.map # fix the symbol position for countries which are not well positioned by centroid
			"FRA" : [2.462206 , 46.623965]
			"FIN" : [25.072069, 61.177713]
			"SUE" : [14.613085, 57.87023 ]

	constructor: (navigation, map, stories) ->
		@story_selected = undefined
		@navigation     = navigation
		@map            = map
		@stories        = stories
		@ui             = $(".map")
		@uis =
			switch_button : $(".switch", @ui)

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
			.center(settings.Map.initial_center)
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
		# reset tooltip, destroy everything
		$("image").qtip('destroy', true)
		$("path") .qtip('destroy', true)
		# remove legend
		$(".scale").remove()
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
		values = []
		for country in countries.values()
			values.push(country["serie1"])
			values.push(country["serie2"])
		values =values.filter((d) -> d? and not isNaN(d))
		domain = [Math.min.apply(Math, values), Math.max.apply(Math, values)]
		scale  = chroma.scale(settings.Map.color_scale).domain(domain, 5, STORIES[@story_selected]['scale_type'])
		 # zoom + move + color animation
		@groupPaths.selectAll('path')
			.attr 'fill', (d) ->
				# star or unstar country
				country = countries.get(d.properties.iso_a3)
				if country
					d3.select(this).classed("discret", country["starred_country(y/n)"] == "no")
				# init color before transition
				d3.select(this).attr("fill") or settings.Map.map_default_color
			.transition()
				.duration(settings.Map.map_transition)
				.attr 'fill', (d) -> # color countries using the color scale
					country = countries.get(d.properties.iso_a3)
					if country?
						# colorize country
						value = country["serie#{serie}"]
						color =  if value? then scale(value).hex() else undefined
					else
						color = settings.Map.map_default_color
					d.color = color
					return color
				.attr("stroke", (d) -> chroma(d.color).darker()) # border color
				# zoom + move
				.attr("transform", @computeZoom(@story_selected))
		# tooltip
		@groupPaths.selectAll('path').each @tooltip(serie=serie)
		# legend
		@showLegend(scale)

	drawSymbolMap: (serie=1) =>
		that      = this
		story     = @stories.get(@story_selected)
		countries = story.data.values()
		# keep only row with value to show
		countries = countries.filter (c) ->
			c["serie#{serie}"]? and not isNaN(c["serie#{serie}"])
		# scale
		values = []
		for country in countries
			values.push(country["serie1"])
			values.push(country["serie2"])
		scale  = d3.scale.linear()
			.domain([Math.min.apply(Math, values), Math.max.apply(Math, values)])
			.range(settings.Map.symbol_scale)
		@groupPaths.selectAll('path')
			.attr 'fill', (d) ->
				# init color before transition
				d3.select(this).attr("fill") or settings.Map.map_default_color
			.transition()
				.duration(settings.Map.map_transition)
				.attr 'fill', (d) ->
					color   = settings.Map.map_default_color
					d.color = color # save color in the path object
				.attr("stroke"   , (d) -> chroma(d.color).darker()) # border color
				.attr("transform", @drawEuropeMap(@story_selected))
		get_symbol_position = (symbol_data) ->
			###
			return the wanted positions to place the symbol.
			If the position is fixed in settings.Map.countries_centers, use these values.
			Otherwise, use the centroid of the country.
			Substract the half of the symbol size to the x and y offset in order to return the symbol center position
			###
			country_code = symbol_data["Country ISO Code"]
			if country_code in settings.Map.countries_centers.keys()
				centroid = settings.Map.countries_centers.get(country_code)
				centroid = that.projection(centroid)
			else
				feature  = that.map.filter((f) -> f.properties["iso_a3"] == country_code)
				centroid = that.path.centroid(feature[0])
			return centroid
					# substract the half of the symbol size to the x and y offset in order to return the symbol center position
					.map((position) -> position - scale(symbol_data["serie#{serie}"])/2)
		#  init symbols: image link, position ...
		@groupSymbols.selectAll("image")
			.data(countries).enter()
			.append("image", ".all-symbols")
				.classed("discret" , (d) -> d["starred_country(y/n)"] == "no")
				.attr("xlink:href" ,        "static/symbols/smiley.png")
				.attr("width"      ,        0)
				.attr("height"     ,        0)
				.attr("x"          , (d) -> get_symbol_position(d)[0])
				.attr("y"          , (d) -> get_symbol_position(d)[1])
				.attr("opacity"    ,        0)
				.on "mouseover"    , (d) ->
					# colorize the country
					color = (p) -> if p.properties["iso_a3"] == d["Country ISO Code"] then "#C1BF39" else p.color
					that.groupPaths.selectAll("path").attr "fill", color
				.on "mouseout"     , (d) -> that.groupPaths.selectAll("path").attr "fill", (p) -> p.color
		# redraw, set the symbol size
		@groupSymbols.selectAll("image")
			.transition()
				.duration(settings.Map.map_transition)
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
				.classed "new-eu-country", (d) -> d.properties.iso_a3 in settings.Map.new_countries

	computeZoom: (story) =>
		### Return the translation instruction as string ex: "translate(1,2)scale(1)"" ###
		zoom      = STORIES[story].zoom or 1
		center    = @projection(STORIES[story].center or settings.Map.initial_center)
		offset_x  = - (center[0] * zoom - @width  / 2)
		offset_y  = - (center[1] * zoom - @height / 2)
		return "translate(#{offset_x},#{offset_y})scale(#{zoom})"

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
							x:  10
							y: -20

	showLegend : (scale) =>
		that = this
		# remove old legend
		$legend = $(".scale")
		$legend.remove()
		# show value legend
		$legend       = $("<div />").addClass("scale")
		domains       = scale.domain()
		legend_size   = 300
		domains_delta = domains[domains.length - 1] - domains[0]
		offset        = 0
		max_height    = 0
		size_by_value = true
		label_size    = 0
		$legend.css "width", legend_size
		_.each domains, (step, i) ->
			size_by_value = false  if (domains[i] - domains[i - 1]) / domains_delta * legend_size < 20  if i > 0
			return
		# rounded_domains = dw.utils.smartRound(domains, 1)
		rounded_domains   = utils.smartRound(domains, 0)
		_.each domains, (step, index) ->
			# for each segment, we adding a domain in the legend and a sticker
			if index < domains.length - 1
				delta = domains[index + 1] - step
				color = scale(step)
				label = rounded_domains[index]
				size  = (if size_by_value then delta / domains_delta * legend_size else legend_size / (domains.length - 1))
				# setting step
				$step = $("<div class='step'></div>")
				$sticker = $("<span class='sticker'></span>").appendTo($legend)
				$step.css
					width: size
					"background-color": color.hex()
				# settings ticker
				$sticker.css "left", offset
				if index > 0
					label_size += size
					if label_size < 30
						label = ""
					else
						label_size = 0
					$("<div />").addClass("value").html(label).appendTo $sticker
				else
					$sticker.remove()
				# add hover effect to highlight regions
				$step.hover ((e) ->
					step_color = chroma.color($(e.target).css("background-color")).hex()
					opacity    = (path) -> if path.color == step_color then 1 else .2
					that.groupPaths.selectAll("path").attr("opacity", opacity)
				), ->
					that.groupPaths.selectAll("path").attr("opacity", 1)

				$legend.append $step
				offset += size

		# title
		$("<div />").prependTo $legend
		@ui.after $legend

# EOF
