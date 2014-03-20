# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : n-host : Map for the 10th anniversary of the EU-enlargement
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 27-Jan-2014
# Last mod : 14-Mar-2014
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
			filterBtn   : $("> .filter"     , @ui)

		#bind events
		$(document).on("storySelected", @onStorySelected)
		@uis.increase.add(@uis.reduce).on "click", (e) => 
			if e.target in _.map([@uis.increase, @uis.reduce], (d) -> d.get(0))
				if @hidden then @show() else @hide()
		@uis.filterBtn.on("click", @onFilterClick)

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
		# reset filter button
		@uis.filterBtn.removeClass("active")
		@uis.filterBtn.removeClass("hidden")

	onFilterClick: =>
		if @uis.filterBtn.hasClass("active")
			$(document).trigger("filterSelected", false)
			@uis.filterBtn.removeClass("active")
		else
			$(document).trigger("filterSelected", true)
			@uis.filterBtn.addClass("active")

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
