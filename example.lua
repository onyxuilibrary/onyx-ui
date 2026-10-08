-- onyx example, shows pretty much everything
local Onyx = loadstring(game:HttpGet("https://raw.githubusercontent.com/onyxuilibrary/onyx-ui/main/source.lua"))()

local window = Onyx:CreateWindow({
	name = "onyx",
	subtitle = "example hub",
	theme = "default", -- default, cobalt, ember, amethyst, frost, rose or a table
	toggleKey = Enum.KeyCode.RightShift,
	configuration = { autoSave = true, autoLoad = true, fileName = "example" },

	status = Onyx.Status.Working, -- Working / Updating / Patched
	statusNote = "everything works on the latest game version",
	-- or keep it in a file you can edit any time without updating the script:
	-- statusUrl = "https://raw.githubusercontent.com/you/your-repo/main/status.txt",

	-- uncomment for a key prompt before the menu opens
	-- keySystem = { keys = { "ONYX-1234" }, note = "key is ONYX-1234", url = "https://example.com" },

	changelog = {
		once = true,
		entries = {
			{ version = "1.1.0", date = "2026-10-08", changes = { "Key system", "Script status", "Changelog popup" } },
			{ version = "1.0.0", changes = { "First release" } },
		},
	},
})

window:CreateTag({ text = "beta", color = Color3.fromRGB(150, 196, 60) })

local aimbot = window:CreateTab({ name = "Aimbot" })
local visuals = window:CreateTab({ name = "Visuals" })
local misc = window:CreateTab({ name = "Misc" })

-- Sections are group boxes; they fill the two columns automatically (or pass side = "left"/"right").
local general = aimbot:CreateSection("General")

general:CreateToggle({
	name = "Enabled",
	flag = "AimEnabled",
	callback = function(on)
		print("aimbot", on)
	end,
})

general:CreateKeybind({
	name = "Aim key",
	value = Enum.UserInputType.MouseButton2,
	hold = true,
	callback = function(held)
		print(held and "aiming" or "released")
	end,
})

general:CreateSlider({
	name = "Field of view",
	range = { 0, 180 },
	increment = 1,
	value = 90,
	suffix = "°",
	callback = function(value, dragging)
		if not dragging then
			print("fov committed", value)
		end
	end,
})

general:CreateDropdown({
	name = "Hitbox",
	options = { "Head", "Neck", "Chest", "Pelvis" },
	value = "Head",
	callback = function(choice)
		print("hitbox", choice)
	end,
})

local trigger = aimbot:CreateSection("Triggerbot")
trigger:CreateToggle({ name = "Enabled", flag = "TriggerEnabled" })
trigger:CreateSlider({ name = "Delay", range = { 0, 500 }, value = 50, suffix = "ms" })
trigger:CreateDropdown({
	name = "Targets",
	options = { "Enemies", "Teammates", "NPCs" },
	multiSelect = true,
	value = { "Enemies" },
	callback = function(list)
		print("targets", table.concat(list, ", "))
	end,
})

local players = visuals:CreateSection("Players")
players:CreateToggle({ name = "Boxes", value = true })
players:CreateColorPicker({
	name = "Box colour",
	color = Color3.fromRGB(255, 80, 80),
	callback = function(color, alpha)
		print("box colour", color, alpha)
	end,
})
players:CreateToggle({ name = "Names" })

local world = visuals:CreateSection("World")
world:CreateSlider({ name = "Brightness", range = { 0, 1 }, increment = 0.05, value = 0.5 })
local row = world:CreateGroup({ direction = "row" })
row:CreateButton({ name = "Day", callback = function() print("day") end })
row:CreateButton({ name = "Night", callback = function() print("night") end })

local stats = misc:CreateSection("Session")
local kills = stats:CreateStat({ name = "Kills", value = 0 })
local progress = stats:CreateProgress({ name = "Level", range = { 0, 100 }, value = 35 })
local log = stats:CreateConsole({ name = "Log", follow = true, maxLines = 100, height = 90 })

local tools = misc:CreateSection("Tools")
tools:CreateInput({
	name = "Walk speed",
	numeric = true,
	value = "16",
	callback = function(text)
		local humanoid = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = tonumber(text)
		end
	end,
})
tools:CreateButton({
	name = "Add kill",
	description = "Bumps the stat and logs it",
	callback = function()
		kills:Set(kills.value + 1)
		progress:Set(math.min(100, progress.value + 5))
		log:Append("kill #" .. kills.value)
	end,
})
tools:CreateDivider({ text = "danger" })
tools:CreateButton({
	name = "Reset everything",
	callback = function()
		window:Popup({
			title = "Reset everything?",
			content = "This clears every saved value.",
			options = {
				{ text = "Cancel" },
				{ text = "Reset", style = "danger", callback = function()
					window.Flags.AimEnabled = false
					window:Toast({ title = "Reset", subtitle = "all values cleared" })
				end },
			},
		})
	end,
})

window:Notify({ title = "Loaded", content = "Press RightShift to toggle the menu." })
