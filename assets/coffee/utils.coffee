#
#     Rounds a set of unique numbers to the lowest
#     precision where the values remain unique
#
utils = {}
utils.smartRound = (values, add_precision) ->
	round = (b) ->
		+(b.toFixed(precision))
	result = []
	precision = 0
	nonEqual = true
	loop
		result = _.map(values, round)
		precision++
		break unless _.uniq(result, true).length < values.length
	if add_precision
		precision += add_precision - 1
		result = _.map(values, round)
	result

# EOF
