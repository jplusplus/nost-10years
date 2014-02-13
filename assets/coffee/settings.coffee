# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : n-host : Map for the 10th anniversary of the EU-enlargement
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 11-Feb-2014
# Last mod : 11-Feb-2014
# -----------------------------------------------------------------------------
#
#    SETTINGS
#
# -----------------------------------------------------------------------------
settings = 
	map :
		map_transition    : 500 # ms
		ratio             : .8
		initial_center    : [23.247769, 50.117286] # lon/lat
		symbol_scale      : [10, 60] # in pixel
		map_default_color : "#003399"
		non_eu_color      : "#D6D6D6"
		color_scale       : "YlOrRd" # http://colrd.com/palette/19079/
		eu_countries      : ["DEU", "AUT", "HRV", "BEL", "BGR", "CYP", "DNK", "ESP", "EST", "FIN", "FRA", "GRC", "HUN", "IRL", "ITA", "LVA", "LTU", "MLT", "LUX", "NLD", "POL", "PRT", "CZE", "ROU", "GBR", "SVK", "SVN", "SWE"]
		new_countries     : ["BGR","EST","LVA","LTU","POL","ROU","SVK","SVN","CZE","HUN"] # for larger border
		countries_centers : d3.map # fix the symbol position for countries which are not well positioned by centroid
			"FRA" : [2.462206 , 46.623965] # lon/lat
			"FIN" : [25.072069, 61.177713]
			"SUE" : [14.613085, 57.87023 ]

	# NOTE: List all the stories
	# key must be the prefix of the story file in static/projects/
	# you can provide some properties like:
	# 		center     : [lon, lat]
	# 		zoom       : int(default=1)
	# 		scale_type : log|quantiles|k-means|linear(default)
	# 		symbol     : path to symbol image file
	stories :
		"n-ost_Project_1"  : {}
		"n-ost_Project_2"  : {}
		"n-ost_Project_3"  :
			symbol   : "static/symbols/korruption-score.jpg"
		"n-ost_Project_4"  :
			symbol   : "static/symbols/landwirschaft.png"
		"n-ost_Project_5b" : {}
		"n-ost_Project_5"  : {}
		"n-ost_Project_6b" : {}
		"n-ost_Project_6"  : {}

# EOF
