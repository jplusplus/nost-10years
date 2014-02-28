# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : n-host : Map for the 10th anniversary of the EU-enlargement
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 11-Feb-2014
# Last mod : 28-Feb-2014
# -----------------------------------------------------------------------------
#
#    SETTINGS
#
# -----------------------------------------------------------------------------
settings = 
	map :
		map_transition    : 750 # ms
		europe_bounds     : [[-11.7,33.6],[35.1,61.4]] # [[lon/lat],[lon/lat]]
		symbol_scale      : [10, 60] # in pixel
		stripped_image    : "static/img/stripped.png"
		eu_color          : "#517FDD"
		new_eu_color      : "#003399"
		non_eu_color      : "#d6d6d6"
		stroke_dark       : "#3D3D3D"
		stroke_light      : "white"
		color_scale       : "YlOrRd" # http://colrd.com/palette/19079/
		eu_countries      : ["DEU", "AUT", "HRV", "BEL", "BGR", "CYP", "DNK", "ESP", "EST", "FIN", "FRA", "GRC", "HUN", "IRL", "ITA", "LVA", "LTU", "MLT", "LUX", "NLD", "POL", "PRT", "CZE", "ROU", "GBR", "SVK", "SVN", "SWE"]
		new_countries     : ["BGR","HRV","EST","LVA","LTU","POL","ROU","SVK","SVN","CZE","HUN"] # for larger border
		countries_centers : d3.map # fix the symbol position for countries which are not well positioned by centroid
			"FRA" : [2.462206 , 46.623965] # lon/lat
			"FIN" : [25.045633, 60.221414]
			"SWE" : [15.333719, 57.754753]
		nb_buckets : 6 # number of buckets for choroplet map
		# Style for tooltip
		tooltip_style :
			style: # http://qtip2.com/options#style
				classes : "qtip-dark qtip-tipsy"
				tip:
					corner: false
			position:
				target: 'mouse'
				adjust:
					x:  40
					y: -10 

	# NOTE: List all the stories
	# key must be the prefix of the story file in static/projects/
	# you can provide some properties like:
	#
	# * GENERAL
	#   - center        : [lon, lat]
	#   - zoom          : int(default=1)
	#
	# * CHOROPLETH MAP
	#   - scale_type    : log|quantiles|k-means|linear(default)
	#   - nb_buckets    : int (default : value of settings.map.nb_buckets)
	#
	# * SYMBOLS MAP
	#   - symbol        : path to symbol image file
	#   - symbol_scale  : range for symbols sizes [min, max] (default : value of settings.map.symbol_scale)
	#   - reverse_scale : reverse the scale
	#
	stories :
		"n-ost_Project_1"  :
			nb_buckets : 4
		"n-ost_Project_2"  : {}
		"n-ost_Project_3"  :
			symbol         : "static/symbols/n-ost_Project_3_icon.png"
			reverse_scale  : true
		"n-ost_Project_4"  : {}
		"n-ost_Project_5"  :
			symbol_scale   : [20, 100]
			symbol         : "static/symbols/landwirschaft.png"
		"n-ost_Project_6"  :
			symbol_scale   : [20, 100]
			symbol         : "static/symbols/n-ost_Project_6_icon.png"
		"n-ost_Project_7"  :
			symbol         : "static/symbols/n-ost_Project_7_icon.png"
			symbol_scale   : [20, 100]
		"n-ost_Project_8"  :
			symbol_scale   : [20, 80]
			symbol         : "static/symbols/n-ost_Project_8_icon.png"
		"n-ost_Project_9b" : {}
		"n-ost_Project_9"  : {}

# EOF
