-- Builds a demo scene and serialises the computed GUI tree for an HTML preview.
local M = __mock
local scene = __SCENE or "main"

local function demo(window)
	local aim = window:CreateTab({ name = "Aimbot" })
	window:CreateTab({ name = "Visuals" })
	window:CreateTab({ name = "Misc" })
	window:CreateTab({ name = "Skins" })

	local general = aim:CreateSection("General")
	general:CreateToggle({ name = "Enabled", value = true })
	general:CreateToggle({ name = "Silent aim", description = "Redirects shots without moving the camera" })
	general:CreateKeybind({ name = "Aim key", value = Enum.UserInputType.MouseButton2, hold = true })
	general:CreateSlider({ name = "Field of view", range = { 0, 180 }, value = 74, suffix = "°" })
	general:CreateSlider({ name = "Smoothing", range = { 0, 1 }, increment = 0.01, value = 0.35 })
	general:CreateDropdown({ name = "Hitbox", options = { "Head", "Neck", "Chest", "Pelvis" }, value = "Head" })
	general:CreateToggle({ name = "Visible only", value = true })

	local trigger = aim:CreateSection("Triggerbot")
	trigger:CreateToggle({ name = "Enabled" })
	trigger:CreateKeybind({ name = "Trigger key", value = Enum.KeyCode.LeftAlt })
	trigger:CreateSlider({ name = "Delay", range = { 0, 500 }, value = 45, suffix = "ms" })
	trigger:CreateDropdown({ name = "Targets", options = { "Enemies", "Teammates", "NPCs" }, multiSelect = true, value = { "Enemies", "NPCs" } })

	local other = aim:CreateSection("Other")
	other:CreateToggle({ name = "Recoil control", value = true })
	other:CreateColorPicker({ name = "FOV circle", color = Color3.fromRGB(150, 196, 60) })
	local row = other:CreateGroup({ direction = "row", perRow = 2 })
	row:CreateButton({ name = "Save" })
	row:CreateButton({ name = "Reset" })
	other:CreateProgress({ name = "Cooldown", range = { 0, 100 }, value = 62 })
	return aim, general, other
end

local base = { name = "onyx", status = "working", configuration = { fileName = "demo" }, discord = "discord.gg/example", infoBar = true }
local function options(extra)
	local t = {}
	for k, v in pairs(base) do t[k] = v end
	for k, v in pairs(extra or {}) do t[k] = v end
	return t
end

local gui
if scene == "main" then
	local w = Onyx:CreateWindow(options())
	demo(w)
	w:Notify({ title = "Config loaded", content = "Restored 18 settings from default.", duration = 60 })
	gui = w._gui
elseif scene == "sidebar" then
	local w = Onyx:CreateWindow(options({ sidebarLayout = true, profile = "premium", theme = "ember" }))
	w:CreateSection("Combat")
	local _, _, other = demo(w)
	M.flush()
	M.click(other.children[2].row:FindFirstChild("Hitbox"))
	gui = w._gui
elseif scene == "settings" then
	local w = Onyx:CreateWindow(options({ status = { state = "updating", note = "Aimbot is being fixed after the last game update." } }))
	demo(w)
	M.flush()
	w:Navigate("Settings")
	gui = w._gui
elseif scene == "keysystem" then
	task.spawn(function()
		Onyx:CreateWindow(options({ keySystem = { keys = { "x" }, note = "Grab a key from our discord. Keys reset every 24 hours.", url = "https://example.com", saveKey = false } }))
	end)
	M.flush()
	gui = M.screenGuis[#M.screenGuis]
	local box = M.find(gui, function(d) return d.Name == "Key" end)
	M.typeInto(box, "ONYX-7F3A-0000")
elseif scene == "changelog" then
	local w = Onyx:CreateWindow(options({
		changelog = {
			entries = {
				{ version = "1.2.0", date = "2026-10-08", changes = { "Key system", "Script status in settings", "Notice + changelog popups" } },
				{ version = "1.1.0", date = "2026-10-01", changes = { "Mobile support", "Launcher button" } },
			},
		},
	}))
	demo(w)
	gui = w._gui
elseif scene == "mobile" then
	M.UIS.TouchEnabled, M.UIS.MouseEnabled = true, false
	local w = Onyx:CreateWindow(options({ scale = 1 }))
	demo(w)
	gui = w._gui
elseif scene == "discord" then
	local w = Onyx:CreateWindow(options({ name = "Noic Hub" }))
	demo(w)
	M.flush()
	w:ShowDiscordPrompt({ joinDelay = 3, continueDelay = 5 })
	gui = w._gui
elseif scene == "crowded" then
	-- lots of top tabs in a narrow window
	local w = Onyx:CreateWindow(options({ subtitle = "lots of tabs", size = UDim2.fromOffset(628, 460), discord = "discord.gg/example", infoBar = true }))
	for _, name in ipairs({ "Rage", "Anti-Aim", "Players", "Weapon", "Skins", "Visuals", "Feedback", "Player", "World", "HUD" }) do
		w:CreateTab({ name = name })
	end
	local t = w:CreateTab({ name = "Misc" })
	local runtime = t:CreateSection("Runtime")
	runtime:CreateLabel("Executor: Volt")
	runtime:CreateLabel("Bullet true | Weapon true | Camera true")
	runtime:CreateStatus()
	runtime:CreateDiscord()
	runtime:CreateButton({ name = "Unload" })
	local theme = t:CreateSection("Theme")
	theme:CreateDropdown({ name = "Preset config", options = { "Default", "Legit" }, value = "Default" })
	theme:CreateToggle({ name = "Rainbow UI" })
	M.flush()
	w:Navigate("Misc")
	gui = w._gui
end
M.flush()

M.advance(1) -- lets the info bar count some frames
-- Serialise
M.freezeLayout(true)
local nodes = {}
local function color(c, t) return { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5), 1 - (t or 0) } end

-- AbsolutePosition starts below the top bar; draw in real screen space
local screenOrigin = gui.AbsolutePosition
local function visit(inst, clip)
	if inst.__class.gui then
		if inst.Visible == false then return end
		local p, s = inst.AbsolutePosition - screenOrigin, inst.AbsoluteSize
		local node = { x = p.X, y = p.Y, w = s.X, h = s.Y, clip = clip }
		node.bg = color(inst.BackgroundColor3, inst.BackgroundTransparency)
		local grad = inst:FindFirstChildOfClass("UIGradient")
		if grad then
			local seq = grad.Color and grad.Color.Keypoints or {}
			local stops = {}
			for _, k in ipairs(seq) do table.insert(stops, { k.Time, color(k.Value) }) end
			local tr = grad.Transparency
			node.grad = { rot = grad.Rotation or 0, stops = stops, t0 = tr and tr.Keypoints[1].Value, t1 = tr and tr.Keypoints[#tr.Keypoints].Value }
		end
		local stroke = inst:FindFirstChildOfClass("UIStroke")
		if stroke then node.stroke = color(stroke.Color) end
		local ok, text = pcall(function() return inst.Text end)
		local isBox = inst.ClassName == "TextBox"
		if ok and ((text and text ~= "") or (isBox and inst.PlaceholderText ~= "")) then
			local placeholder = isBox and text == ""
			node.text = placeholder and inst.PlaceholderText or text
			node.tc = placeholder and color(inst.PlaceholderColor3) or color(inst.TextColor3, inst.TextTransparency)
			node.ts = inst.TextSize
			node.xa = inst.TextXAlignment.Name
			node.ya = inst.TextYAlignment.Name
			node.wrap = inst.TextWrapped
			local t, r, b, l = 0, 0, 0, 0
			local pad = inst:FindFirstChildOfClass("UIPadding")
			if pad then t, r, b, l = pad.PaddingTop.Offset, pad.PaddingRight.Offset, pad.PaddingBottom.Offset, pad.PaddingLeft.Offset end
			node.pad = { t, r, b, l }
		end
		local okImg, image = pcall(function() return inst.Image end)
		if okImg and image and image ~= "" then
			node.img = image:match("^rbxthumb") and "avatar" or "icon"
		end
		table.insert(nodes, node)
		if inst.ClipsDescendants then
			local r = { p.X, p.Y, p.X + s.X, p.Y + s.Y }
			if clip then r = { math.max(r[1], clip[1]), math.max(r[2], clip[2]), math.min(r[3], clip[3]), math.min(r[4], clip[4]) } end
			clip = r
		end
	end
	local kids = inst:GetChildren()
	local order = {}
	for i, c in ipairs(kids) do order[i] = { c = c, i = i } end
	table.sort(order, function(a, b)
		local za = a.c.__class.gui and a.c.ZIndex or 0
		local zb = b.c.__class.gui and b.c.ZIndex or 0
		if za == zb then return a.i < b.i end
		return za < zb
	end)
	for _, e in ipairs(order) do visit(e.c, clip) end
end
visit(gui, nil)
__RENDER_JSON = game:GetService("HttpService"):JSONEncode(nodes)
