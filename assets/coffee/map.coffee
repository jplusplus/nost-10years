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

	# Define default settings
	CONFIG = settings.map

	constructor: (navigation, map, stories) ->
		@story_selected = undefined
		@navigation     = navigation
		@map            = map
		@stories        = stories
		@ui             = $(".map")
		@uis =
			legend        : $(".legend"        , @ui)
			scale         : $(".legend .scale" , @ui)
			title         : $(".legend .title" , @ui)
			source        : $(".legend .source", @ui)
			switch_button : $(".switch"        , @ui)

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
		@ui.css("width" , @width)

		# Create projection
		@projection = d3.geo.mercator()
			.center(CONFIG.initial_center)
			.scale(@width * CONFIG.ratio)
			.translate([@width/2, @height/2])
		# Create the path
		@path  = d3.geo.path().projection(@projection)
		@group = @svg.append("g")
		# Create the group of path
		@groupPaths   = @group.append("g").attr("class", "all-path")
		@groupSymbols = @groupPaths.append("g").attr("class", "all-symbols")
		@drawEuropeMap()
		# draw the map if a story is selected
		@drawMap(@story_selected) if @story_selected?

	onStorySelected : (e, story_key) =>
		previous_story =  @stories.get(@story_selected)
		# save the selected story
		@story_selected = story_key
		# update the map
		infos = @stories.get(@story_selected).infos
		# don't reset color between 2 choropleth maps
		reset_color = not (previous_story and not previous_story.infos.is_symbol and not infos.is_symbol)
		@drawMap(story_key, serie=1, reset_color=reset_color)
		# update switch button
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

	drawMap: (story_key, serie=1, reset_color=false) =>
		# reset tooltip, destroy everything
		$("image").qtip('destroy', true)
		$("path") .qtip('destroy', true)
		#reset the color if needed
		@resetMapColor(reset_color) if reset_color
		# remove legend, title and source
		@uis.scale.html("")
		@uis.title.html("")
		@uis.source.html("")
		story  = @stories.get(@story_selected)
		# select the right method
		if story.infos.is_symbol
			@drawSymbolMap(serie)
		else
			@groupSymbols.selectAll("image").remove()
			@drawChoroplethMap(serie)
		# show title ans sources
		@setTitle()
		@setSource()

	drawChoroplethMap: (serie=1) =>
		countries = @stories.get(@story_selected).data
		# scale
		values = []
		for country in countries.values()
			values.push(country["serie1"])
			values.push(country["serie2"])
		values =values.filter((d) -> d? and not isNaN(d))
		domain = [Math.min.apply(Math, values), Math.max.apply(Math, values)]
		scale  = chroma.scale(CONFIG.color_scale).domain(domain, 5, settings.stories[@story_selected]['scale_type'])
		 # zoom + move + color animation
		@groupPaths.selectAll('path')
			.classed "discret", (d) ->
				country = countries.get(d.properties.iso_a3)
				d.is_discrete = true
				if country
					d.is_discrete = country["starred_country(y/n)"]!= "yes"
				return d.is_discrete
			.transition()
				.duration(CONFIG.map_transition)
				.attr "stroke", (d) ->
					# save the color to animate the filling
					country = countries.get(d.properties.iso_a3)
					if country?
						value = country["serie#{serie}"]
						color =  if value? then scale(value).hex() else undefined
					else
						color = d3.select(this).attr("fill")
					d.color = color
					return chroma(color).darker().hex()
				.attr 'fill', (d) -> # color countries using the color scale
					country = countries.get(d.properties.iso_a3)
					if country?
					# 	# colorize country
						value = country["serie#{serie}"]
						color =  if value? then scale(value).hex() else undefined
					else
						color = d3.select(this).attr("fill")
					d.color = color
					return color
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
		# countries = countries.filter (c) ->
		# 	c["serie#{serie}"]? and not isNaN(c["serie#{serie}"])
		# scale
		values = []
		for country in countries
			values.push(country["serie1"])
			values.push(country["serie2"])
		values = values.filter((n) -> not isNaN(n))
		scale  = d3.scale.linear()
			.domain([Math.min.apply(Math, values), Math.max.apply(Math, values)])
			.range(CONFIG.symbol_scale)
		# map
		@groupPaths.selectAll('path')
			.on "mouseover", (d) ->
				nui_symb = that.groupSymbols.selectAll("image").filter((s) -> s["Country ISO Code"] == d.properties["iso_a3"])
				nui_symb.classed("discret", false)
			.on "mouseout",  (d) ->
				nui_symb = that.groupSymbols.selectAll("image").filter((s) -> s["Country ISO Code"] == d.properties["iso_a3"])
				nui_symb.classed("discret", d.is_discrete)
			.classed "discret", (d) =>
				country = @stories.get(@story_selected).data.get(d.properties["iso_a3"])
				d.is_discrete = true
				if country
					d.is_discrete = country["starred_country(y/n)"]!= "yes"
				return d.is_discrete
			.transition()
				.duration(CONFIG.map_transition)
				.attr("transform", @computeZoom(@story_selected))

		#  init symbols: image link, position ...
		@symbol =@groupSymbols.selectAll("image").data(countries)
		@symbol.enter()
			.append("image"        , ".all-symbols")
				.attr("width"      , 0)
				.attr("height"     , 0)
				.attr("opacity"    , 0)
		@symbol.exit().remove()

		get_symbol_position = (symbol_data) ->
			###
			return the wanted positions to place the symbol.
			If the position is fixed in CONFIG.countries_centers, use these values.
			Otherwise, use the centroid of the country.
			Substract the half of the symbol size to the x and y offset in order to return the symbol center position
			###
			country_code = symbol_data["Country ISO Code"]
			if country_code in CONFIG.countries_centers.keys()
				centroid = CONFIG.countries_centers.get(country_code)
				centroid = that.projection(centroid)
			else
				feature  = that.map.filter((f) -> f.properties["iso_a3"] == country_code)
				centroid = that.path.centroid(feature[0])
			return centroid
					# FIXME: this code causes an offset before the transition
					# substract the half of the symbol size to the x and y offset in order to return the symbol center position
					# .map((position) -> position - scale(symbol_data["serie#{serie}"])/2)

		# redraw, set the symbol size
		@groupSymbols.selectAll("image")
			.attr("x"          , (d) -> get_symbol_position(d)[0])
			.attr("y"          , (d) -> get_symbol_position(d)[1])
			.classed("discret" , (d) -> d["starred_country(y/n)"] == "no")
			.attr("xlink:href" ,     -> settings.stories[that.story_selected].symbol or "static/symbols/smiley.png")
			.on "mouseover"    , (d) ->
				# colorize the country
				that.groupPaths.selectAll("path").filter((p) -> p.properties["iso_a3"] == d["Country ISO Code"])
					.classed("discret", false)
			.on "mouseout"     , (d) ->
				that.groupPaths.selectAll("path").filter((p) -> p.properties["iso_a3"] == d["Country ISO Code"])
					.classed("discret", (p) -> p.is_discrete)
			.transition()
				.duration(CONFIG.map_transition)
				.attr("opacity", 1)
				.attr "transform", (d)->
					return that.computeZoom(that.story_selected)\# add the zoom transformation
						# add the transformation to use the center of the picture as placed point
						+ "translate(#{-scale(d["serie#{serie}"])/2}, #{-scale(d["serie#{serie}"])/2})"
				.attr("width"  , (d) -> if isNaN(d["serie#{serie}"]) then 0 else scale(d["serie#{serie}"]))
				.attr("height" , (d) -> if isNaN(d["serie#{serie}"]) then 0 else scale(d["serie#{serie}"]))
		# tooltip
		@groupSymbols.selectAll("image").each(@tooltip(serie=serie))
		@groupPaths.selectAll('path').each(@tooltip(serie=serie))

	drawEuropeMap: =>
		###
		Create every countries
		Set a classe new-eu-country for new countries
		Colorize them with 2 colors (UE countries or other)
		Colorize the border
		###
		@groupPaths.selectAll("path")
			.data(@map)
			.enter()
				.insert("path", ".all-symbols")
				.classed("new-eu-country", (d) -> d.properties.iso_a3 in CONFIG.new_countries)
			.attr("d", @path)
		@resetMapColor()

	resetMapColor: =>
		###
		Colorize them with 2 colors (UE countries or other)
		Colorize the border
		###
		@groupPaths.selectAll("path")
			.transition().duration(0) # cancel the previous transition if exists
			.attr("fill"  , (d) -> 
				if d.properties["iso_a3"] in CONFIG.eu_countries # if in EU
					return CONFIG.map_default_color
				else
					return CONFIG.non_eu_color
			)
			.attr "stroke", (d) ->
				if d.properties["iso_a3"] in CONFIG.eu_countries # if in EU
					return chroma(CONFIG.map_default_color).brighten() # border color
				else
					return CONFIG.non_eu_color

	computeZoom: (story) =>
		### Return the translation instruction as string ex: "translate(1,2)scale(1)"" ###
		scale          = settings.stories[story].zoom or 1
		center         = @projection(settings.stories[story].center or CONFIG.initial_center)
		offset_x       = - (center[0] * scale - @width  / 2)
		offset_y       = - (center[1] * scale - @height / 2)
		transformation = "translate(#{offset_x},#{offset_y})scale(#{scale})"
		return transformation

	tooltip: (serie) =>
		### use the @story_selected to create tooltip depending of the given serie ###
		return ((context) ->
			(d) ->
				# retrieve data, depending of the element type (feature or symbol)
				data  = if d.properties? then context.stories.get(context.story_selected).data.get(d.properties.iso_a3) else d
				country_name = if data? then data["Country name"]            else ""
				value        = if data? then data["serie#{serie}"]or "k. A." else ""
				append       = if data? and value != "k. A." then data["Append Sign (€,%, Mio, etc)"] or "" else ""
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
		)(this)

	setTitle : (title=null) =>
		@uis.title.html(title or @stories.get(@story_selected).infos["Legend text"])

	setSource: (source_text=null, source_url=null) =>
		if not source_text? and not source_url?
			info = @stories.get(@story_selected).infos
			source_text = info["Title of the source"]
			source_url  = info["Url of the source"]
		nui = $("<a />").attr("href", source_url).html(source_text)
		@uis.source.html(nui)

	showLegend : (scale) =>
		that = this
		# remove old legend
		@uis.scale.html("")
		# show value legend
		domains       = scale.domain()
		legend_size   = 300
		domains_delta = domains[domains.length - 1] - domains[0]
		offset        = 0
		max_height    = 0
		size_by_value = true
		label_size    = 0
		@uis.legend.css "width", legend_size
		_.each domains, (step, i) ->
			size_by_value = false  if (domains[i] - domains[i - 1]) / domains_delta * legend_size < 20  if i > 0
			return
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
				$sticker = $("<span class='sticker'></span>").appendTo(that.uis.scale)
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
				that.uis.scale.append $step
				offset += size

# EOF
