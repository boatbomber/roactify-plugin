local StudioService = game:GetService("StudioService")

local Plugin = script.Parent.Parent.Parent

local StudioPlugin = require(Plugin.Packages.StudioPlugin)
local StudioTheme = require(Plugin.Packages.StudioTheme)
local RoduxHooks = require(Plugin.Packages.RoduxHooks)
local Roact = require(Plugin.Packages.Roact)
local Hooks = require(Plugin.Packages.Hooks)

local Frameworks = require(Plugin.Lib.Codify.Frameworks)
local Thunks = require(Plugin.Thunks)

local FrameworkSelect = require(Plugin.Components.FrameworkSelect)
local TextInput = require(Plugin.Components.TextInput)
local Button = require(Plugin.Components.Button)
local Layout = require(Plugin.Components.Layout)
local Alert = require(Plugin.Components.Alert)
local Text = require(Plugin.Components.Text)
local Icon = require(Plugin.Components.Icon)

local e = Roact.createElement

local IS_WINDOWS = game:GetService("GuiService").IsWindows
local COPY_TEXT = if IS_WINDOWS then "CTRL+C to Copy" else "Command+C to Copy"

local function Page(_, hooks)
	local theme, styles = StudioTheme.useTheme(hooks)
	local showCopy, setShowCopy = hooks.useState(false)

	local dispatch = RoduxHooks.useDispatch(hooks)
	local plugin = StudioPlugin.usePlugin(hooks)

	local targetInstance = RoduxHooks.useSelector(hooks, function(state)
		return state.targetInstance
	end)

	local userSettings = RoduxHooks.useSelector(hooks, function(state)
		return state.userSettings
	end)

	local snippet = RoduxHooks.useSelector(hooks, function(state)
		return state.snippet
	end)

	local activeSelection = hooks.useMemo(function()
		local name = "Nothing selected"
		local icon = StudioService:GetClassIcon("Instance")

		if targetInstance.instance then
			name = targetInstance.instance.Name
			icon = StudioService:GetClassIcon(targetInstance.instance.ClassName)
		end

		return {
			name = name,
			icon = icon,
		}
	end, { targetInstance })

	return e(Layout.ScrollColumn, {
		paddingTop = styles.spacing,
		paddingBottom = styles.spacing,
	}, {
		padding = e(Layout.Padding),

		framework = e(FrameworkSelect, {
			order = 10,
		}),

		settingsHint = e(Text, {
			text = "Output formatting can be configured in the Settings tab.",
			textColour = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText),
			order = 15,
		}),

		activeSelection = e(Layout.Frame, {
			order = 20,
		}, {
			padding = e(Layout.Padding, { 0, 16, 0, 0 }),
			layout = e(Layout.ListLayout),

			icon = e(Icon, {
				icon = activeSelection.icon.Image,
				imageOffset = activeSelection.icon.ImageRectOffset,
				imageSize = activeSelection.icon.ImageRectSize,
				colour = Color3.new(1, 1, 1),
				size = 16,
				order = 10,
			}),

			label = e(Text, {
				text = activeSelection.name,
				font = styles.font.mono,
				textSize = styles.fontSize + 2,
				order = 20,
			}),
		}),

		largeInstance = targetInstance.large and e(Alert, {
			label = "This Instance appears to have a lot of children! Can it be broken into smaller components?",
			variant = Enum.MessageType.MessageWarning,
			order = 30,
		}),

		generateButton = e(Button, {
			order = 40,
			label = "Generate Snippet",
			primary = not targetInstance.large,
			size = UDim2.fromScale(1, 0),
			autoSize = Enum.AutomaticSize.Y,
			disabled = targetInstance.instance == nil or snippet.processing,

			onActivated = function()
				dispatch(Thunks.GenerateSnippet())
			end,
		}),

		snippet = e(Layout.Frame, {
			order = 50,
		}, {
			layout = e(Layout.ListLayout, {
				direction = Enum.FillDirection.Vertical,
				alignX = Enum.HorizontalAlignment.Right,
			}),

			snippetText = e(TextInput, {
				order = 20,
				placeholder = (Frameworks[userSettings.framework] or {}).Sample,
				text = snippet.content,
				font = styles.font.mono,
				textSize = styles.fontSize + 2,
				readonly = true,
				disabled = snippet.content == nil,
				wrapped = false,
				selectAllOnFocus = true,
				syntaxHighlight = userSettings.syntaxHighlighting,

				onFocus = function()
					setShowCopy(true)
				end,

				onFocusLost = function()
					setShowCopy(false)
				end,
			}),

			copyText = showCopy and e(Text, {
				text = COPY_TEXT,
				textColour = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText),
				textSize = styles.fontSize - 2,
				font = styles.font.semibold,
				order = 30,
			}),

			downloadButton = e(Button, {
				primary = true,
				disabled = snippet.content == nil,
				order = 40,
				label = "Save to Device",
				icon = "Download",

				onActivated = function()
					dispatch(Thunks.ExportSnippetToDevice(plugin))
				end,
			}),
		}),
	})
end

return Hooks.new(Roact)(Page)
