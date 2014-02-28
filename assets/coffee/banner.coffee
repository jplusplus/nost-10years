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
		title       = @navigation.stories.get(story_key).infos['Title of the tab']
		description = @navigation.stories.get(story_key).infos['Introduction']
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

# EOF
