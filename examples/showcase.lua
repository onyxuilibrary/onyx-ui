-- onyx showcase: every feature from the recent updates in one hub.
-- nothing in here touches the game, the buttons just print, notify and show things off.
-- paste it in your executor, or load it with:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/onyxuilibrary/onyx-ui/main/examples/showcase.lua"))()

local Onyx = loadstring(game:HttpGet("https://raw.githubusercontent.com/onyxuilibrary/onyx-ui/main/source.lua"))()

-- pictures for the skin gallery. they live in this repo, swap them for your own links
local IMAGES = "https://raw.githubusercontent.com/onyxuilibrary/onyx-ui/main/examples/images/"
local skins = {
	{ name = "Dragon Lore", image = IMAGES .. "dragon.png", color = Color3.fromRGB(235, 75, 75) },
	{ name = "Howl", image = IMAGES .. "howl.png", color = Color3.fromRGB(235, 75, 75) },
	{ name = "Asiimov", image = IMAGES .. "asiimov.png", color = Color3.fromRGB(211, 44, 230) },
	{ name = "Fade", image = IMAGES .. "fade.png", color = Color3.fromRGB(211, 44, 230) },
	{ name = "Doppler", image = IMAGES .. "doppler.png", color = Color3.fromRGB(136, 71, 255) },
	{ name = "Tiger Tooth", image = IMAGES .. "tiger.png", color = Color3.fromRGB(75, 105, 255) },
	{ name = "Default" }, -- tiles don't need a picture
}
local skinLinks = {}
for _, skin in ipairs(skins) do
	if skin.image then
		table.insert(skinLinks, skin.image)
	end
end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

local window = Onyx:CreateWindow({
	name = "Showcase",
	subtitle = "onyx 1.7",
	configuration = { fileName = "showcase" },

	-- loading screen: manual, so the steps below drive it. use loadingScreen = true for the automatic one
	loadingScreen = { manual = true },

	-- status badge (the dot pings on "working"). statusUrl lets you change it from a text file
	status = "working",
	statusNote = "every feature in here is a demo",
	-- statusUrl = "https://raw.githubusercontent.com/you/your-repo/main/status.txt",

	-- discord: logo button in the title bar + settings, and the join prompt after loading
	discord = "https://discord.gg/yourcode",
	discordPrompt = { joinDelay = 1, continueDelay = 3, once = true },

	-- info bar: fps, ping, executor, time and your name. drag it anywhere
	infoBar = { fields = { "fps", "ping", "executor", "time", "player" } },

	-- languages: english and russian here. the library's own text is already translated,
	-- this table does your tab / section / element names
	languages = { "en", "ru" },
	translations = {
		ru = {
			Skins = "Скины",
			Visuals = "Визуалы",
			Extras = "Разное",
			Window = "Окно",
			["Knife skin"] = "Скин ножа",
			Preview = "Превью",
			Apply = "Применить",
			Boxes = "Боксы",
			Names = "Имена",
			Tracers = "Трейсеры",
			Chams = "Чамсы",
			["ESP colour"] = "Цвет ESP",
			["Open ESP preview"] = "Открыть превью ESP",
			Links = "Ссылки",
			Colours = "Цвета",
			Messages = "Сообщения",
			Script = "Скрипт",
			Behaviour = "Поведение",
			Look = "Вид",
			Dummy = "Манекен",
		},
	},

	-- the small mobile button shows this letter (or set showIcon to a picture)
	showName = "Showcase",

	-- changelog that pops up once per version
	changelog = {
		once = true,
		entries = {
			{ version = "1.7.0", changes = { "Keep on screen, lock, center, UI scale in settings", "Switch toggles", "Nicer sliders and dropdowns" } },
			{ version = "1.6.0", changes = { "Intro animation", "ESP preview", "Links", "Accent colour picker" } },
			{ version = "1.5.0", changes = { "Loading screen", "Images and skin gallery", "Mobile button" } },
		},
	},
})

-- the loading screen is up now and nobody can see the menu, so set things up behind it
window:SetLoading("Authenticating...", 0.1)
task.wait(0.6)

-- downloads the skin pictures (cached after the first run). the bar shows "Loading images 2/6"
window:PreloadImages(skinLinks)

window:SetLoading("Loading features...", 0.85)

--------------------------------------------------------------------------------
-- Skins: image gallery + image preview
--------------------------------------------------------------------------------

local skinsTab = window:CreateTab({ name = "Skins" })

local knives = skinsTab:CreateSection({ name = "Knife skin", side = "left" })
local previewSection = skinsTab:CreateSection({ name = "Preview", side = "right" })

local preview = previewSection:CreateImage({ image = skins[4].image, height = 120 })
local wear = previewSection:CreateDropdown({ name = "Wear", options = { "Factory New", "Minimal Wear", "Field-Tested" }, value = "Factory New" })
local statTrak = previewSection:CreateToggle({ name = "StatTrak", style = "switch", value = true })

local gallery = knives:CreateImageGallery({
	flag = "ShowcaseKnife",
	columns = 2,
	search = true,
	items = skins,
	value = "Fade",
	callback = function(name, item)
		-- show the picked skin on the right (Default has no picture, so it clears)
		preview:Set(item and item.image or nil)
	end,
})

previewSection:CreateButton({
	name = "Apply",
	callback = function()
		local pick = gallery.value[1] or "nothing"
		window:Notify({
			title = "Applied",
			content = pick .. " (" .. wear.value[1] .. (statTrak.value and ", StatTrak" or "") .. ")",
			icon = gallery:GetItem(pick) and gallery:GetItem(pick).image or nil, -- icons take links too
		})
	end,
})

--------------------------------------------------------------------------------
-- Visuals: ESP preview bound to toggles and a colour picker
--------------------------------------------------------------------------------

local visualsTab = window:CreateTab({ name = "Visuals" })
local esp = visualsTab:CreateSection({ name = "ESP", side = "left" })

esp:CreateToggle({ name = "Boxes", flag = "ShowcaseBoxes", value = true })
esp:CreateToggle({ name = "Names", flag = "ShowcaseNames", value = true })
esp:CreateToggle({ name = "Health bar", flag = "ShowcaseHealth", value = true })
esp:CreateToggle({ name = "Distance", flag = "ShowcaseDistance", value = true })
esp:CreateToggle({ name = "Tracers", flag = "ShowcaseTracers" })
esp:CreateToggle({ name = "Chams", flag = "ShowcaseChams" })
esp:CreateColorPicker({ name = "ESP colour", flag = "ShowcaseEspColour", color = Color3.fromRGB(255, 70, 70) })
esp:CreateColorPicker({ name = "Chams colour", flag = "ShowcaseChamsColour", color = Color3.fromRGB(60, 200, 255), alpha = 0.6 })

-- the preview follows those toggles and pickers by flag, live
local espPreview = window:CreateESPPreview({
	playerName = "Dummy",
	bind = {
		box = "ShowcaseBoxes",
		name = "ShowcaseNames",
		health = "ShowcaseHealth",
		distance = "ShowcaseDistance",
		tracer = "ShowcaseTracers",
		chams = "ShowcaseChams",
		boxColor = "ShowcaseEspColour",
		tracerColor = "ShowcaseEspColour",
		chamsColor = "ShowcaseChamsColour",
	},
})
esp:CreateButton({ name = "Open ESP preview", callback = function()
	espPreview:Toggle()
end })

local fakeHealth = visualsTab:CreateSection({ name = "Dummy", side = "right" })
fakeHealth:CreateSlider({
	name = "Dummy health",
	range = { 0, 100 },
	value = 72,
	callback = function(value)
		espPreview:Set("healthAmount", value)
	end,
})
fakeHealth:CreateSlider({
	name = "Dummy distance",
	range = { 5, 500 },
	value = 34,
	suffix = "m",
	callback = function(value)
		espPreview:Set("distanceText", value .. "m")
	end,
})
fakeHealth:CreateText({ text = "The preview only draws a picture. A real ESP is your script's job." })

--------------------------------------------------------------------------------
-- Extras: links, status, discord, colours, messages
--------------------------------------------------------------------------------

local extras = window:CreateTab({ name = "Extras" })

local links = extras:CreateSection({ name = "Links", side = "left" })
links:CreateLink({ name = "Onyx on GitHub", url = "https://github.com/onyxuilibrary/onyx-ui" })
links:CreateLink({ name = "Docs", url = "https://github.com/onyxuilibrary/onyx-ui/tree/main/docs" })
links:CreateDiscord() -- uses the window's discord invite

local scriptInfo = extras:CreateSection({ name = "Script", side = "left" })
scriptInfo:CreateStatus() -- the same badge as in settings, follows SetStatus
scriptInfo:CreateDropdown({
	name = "Try a status",
	options = { "working", "updating", "patched" },
	value = "working",
	callback = function(state)
		if state then
			window:SetStatus(state, state == "patched" and "down until the next update" or nil)
		end
	end,
})

local colours = extras:CreateSection({ name = "Colours", side = "right" })
colours:CreateColorPicker({
	name = "Menu colour",
	color = window.Theme.Accent,
	callback = function(color)
		window:SetAccent(color) -- same as the Accent colour picker in Settings
	end,
})
colours:CreateButton({ name = "Orange", callback = function()
	window:SetAccent(Color3.fromRGB(255, 120, 40))
end })
colours:CreateButton({ name = "Rainbow top bar", callback = function()
	window:SetRainbow(not window.Theme.Rainbow)
end })

local messages = extras:CreateSection({ name = "Messages", side = "right" })
local row = messages:CreateGroup({ direction = "row", perRow = 2 })
row:CreateButton({ name = "Notify", callback = function()
	window:Notify({ title = "Hello", content = "Notifications can be turned off in Settings." })
end })
row:CreateButton({ name = "Toast", callback = function()
	window:Toast({ title = "Saved", subtitle = "toasts always show" })
end })
row:CreateButton({ name = "Popup", callback = function()
	window:Popup({
		title = "Sure?",
		content = "Popups can have as many buttons as you want.",
		options = { { text = "No" }, { text = "Yes", style = "primary" } },
	})
end })
row:CreateButton({ name = "Discord prompt", callback = function()
	window:ShowDiscordPrompt({ continueDelay = 2 })
end })

--------------------------------------------------------------------------------
-- Window: the interface settings from code
--------------------------------------------------------------------------------

local windowTab = window:CreateTab({ name = "Window" })
local behaviour = windowTab:CreateSection({ name = "Behaviour", side = "left" })
behaviour:CreateText({ text = "These are also in the Settings tab. Here's how to set them from a script." })
behaviour:CreateToggle({ name = "Keep on screen", style = "switch", value = true, callback = function(on)
	window:SetKeepOnScreen(on)
end })
behaviour:CreateToggle({ name = "Lock position", style = "switch", callback = function(on)
	window:SetLockPosition(on)
end })
behaviour:CreateButton({ name = "Center window", callback = function()
	window:CenterWindow()
end })

local look = windowTab:CreateSection({ name = "Look", side = "right" })
look:CreateSlider({ name = "UI scale", range = { 50, 150 }, increment = 5, value = 100, suffix = "%", callback = function(value, dragging)
	if not dragging then
		window:SetUIScale(value / 100)
	end
end })
look:CreateToggle({ name = "Animations", style = "switch", value = true, callback = function(on)
	window:SetAnimations(on)
end })
look:CreateDropdown({ name = "Language", options = { "English", "Русский" }, value = "English", callback = function(name)
	window:SetLocale(name == "Русский" and "ru" or "en")
end })

--------------------------------------------------------------------------------
-- Done: the loading card fades, the menu glides in, then the discord prompt and changelog
--------------------------------------------------------------------------------

task.wait(0.4)
window:FinishLoading()
