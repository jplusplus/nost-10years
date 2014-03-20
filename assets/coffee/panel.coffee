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
#    PANEL
#
# -----------------------------------------------------------------------------
class Panel

	constructor: (navigation, stories) ->
		@navigation = navigation
		@stories    = stories
		@uis = 
			panel     : $(".panel.stories")
			story_tmpl: $(".subpanel.template", ".panel.stories")

		# init the panel
		@setStories(stories)

		#bind events
		$(document).on("storySelected", @onStorySelected)
		@selectStories().on "click", (e) =>
			story_key = $(e.currentTarget).find(".story").attr('data-story')
			@navigation.selectStory(story_key)

	selectStories: => $(".subpanel:not(.template)", @uis.panel)

	setStories: (stories) =>
		### reset the stories list ###
		@selectStories().remove() # remove previous stories
		for item in stories.entries()
			nui = @createStory(item.key, item.value)
			@uis.panel.append(nui) # add to DOM

	createStory: (key, story) =>
		### Clone from a template a story item and fill out the field ###
		nui = @uis.story_tmpl.clone().removeClass("template")
		nui.find(".title").html(nui.find(".title").html() + story.infos['Title of the tab'])
		nui.find(".story").html(story.infos['Title']).attr("data-story",key)
		return nui

	onStorySelected: (e, story) =>
		@selectStories().find(".story").each (i, nui) ->
			$(nui).toggleClass("active", $(nui).attr('data-story') == story)

# EOF
