# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : n-host : Map for the 10th anniversary of the EU-enlargement
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 11-Feb-2014
# Last mod : 06-Mar-2014
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
		eu_color          : "#517FDD"
		new_eu_color      : "#003399"
		non_eu_color      : "#d6d6d6"
		stroke_dark       : "#B9B9B9"
		stroke_light      : "#C8C8C8"
		color_scale       : ['rgb(158,202,225)','rgb(107,174,214)','rgb(66,146,198)','rgb(33,113,181)','rgb(8,69,148)', "#001261"] # http://colorbrewer2.org/?type=sequential&scheme=Blues&n=7
		eu_countries      : ["DEU", "AUT", "HRV", "BEL", "BGR", "CYP", "DNK", "ESP", "EST", "FIN", "FRA", "GRC", "HUN", "IRL", "ITA", "LVA", "LTU", "MLT", "LUX", "NLD", "POL", "PRT", "CZE", "ROU", "GBR", "SVK", "SVN", "SWE"]
		new_countries     : ["BGR","HRV","EST","LVA","LTU","POL","ROU","SVK","SVN","CZE","HUN"]  # for larger border
		countries_centers : d3.map # fix the symbol position for countries which are not well positioned by centroid
			"FRA" : [2.462206 , 46.623965] # lon/lat
			"FIN" : [25.045633, 60.221414]
			"SWE" : [15.333719, 57.754753]
			"RUS" : [34.615626, 53.217433]
			"CYP" : [34.718967, 35.44419]
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
			nb_buckets : 5
		"n-ost_Project_2"  :
			center : [21.869254, 50.248456] # pologne
		"n-ost_Project_3"  :
			symbol         : "static/symbols/n-ost_Project_3_icon.png"
			reverse_scale  : true
		"n-ost_Project_4"  :
			nb_buckets : 5
			center : [21.869254, 50.248456] # pologne
		"n-ost_Project_5"  :
			symbol_scale   : [10, 70]
			symbol         : "static/symbols/landwirschaft.png"
		"n-ost_Project_6"  :
			symbol_scale   : [20, 70]
			symbol         : "static/symbols/n-ost_Project_6_icon.png"
		"n-ost_Project_7"  :
			symbol         : "static/symbols/n-ost_Project_7_icon.png"
			symbol_scale   : [20, 70]
		"n-ost_Project_8"  :
			symbol_scale   : [20, 70]
			symbol         : "static/symbols/n-ost_Project_8_icon.png"
		"n-ost_Project_9"  :
			symbol_scale   : [10, 80]
			symbol         : "static/symbols/n-ost_Project_9_icon.png"
		"n-ost_Project_9b" : {}

# EOF
