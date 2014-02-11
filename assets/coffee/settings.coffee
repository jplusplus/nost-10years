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
	Map :
		map_transition    : 1000
		ratio             : .8
		initial_center    : [23.247769, 50.117286]
		symbol_scale      : [20, 60]
		map_default_color : "#D6D6D6"
		color_scale       : "YlOrRd" # http://colrd.com/palette/19079/
		new_countries     : ["BGR","EST","LVA","LTU","POL","ROU","SVK","SVN","CZE","HUN"] # for larger border
		countries_centers : d3.map # fix the symbol position for countries which are not well positioned by centroid
			"FRA" : [2.462206 , 46.623965]
			"FIN" : [25.072069, 61.177713]
			"SUE" : [14.613085, 57.87023 ]

# EOF
