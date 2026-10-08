local M = __mock
local passed, failed = 0, 0
local current = "?"

local function section(name)
	current = name
	print("\n== " .. name)
end

local function check(cond, msg)
	if cond then
		passed = passed + 1
	else
		failed = failed + 1
		print("  FAIL [" .. current .. "] " .. msg)
	end
end

local function eq(actual, expected, msg)
	check(actual == expected, msg .. " (expected " .. tostring(expected) .. ", got " .. tostring(actual) .. ")")
end

local function hitbox(parent)
	return parent:FindFirstChild("Hitbox", true) or M.find(parent, function(d) return d.Name == "Hitbox" end)
end

local function warned(pattern)
	for _, w in ipairs(M.warnings) do
		if string.find(w, pattern, 1, true) then return true end
	end
	return false
end

local function noErrors(label)
	check(#M.errors == 0, label .. ": " .. (M.errors[1] or ""))
	M.errors = {}
end

--------------------------------------------------------------------------------
section("window creation")
--------------------------------------------------------------------------------

local window = Onyx:CreateWindow({
	name = "Onyx Test",
	subtitle = "v1",
	icon = 123,
	theme = "default",
	toggleKey = Enum.KeyCode.RightShift,
	configuration = { autoSave = true, autoLoad = true, fileName = "test", customFolder = "suite" },
})
M.flush()
check(window ~= nil, "window returned")
local gui = window._gui
eq(gui.Parent, M.CoreGui, "gui mounted in CoreGui")
check(gui.IgnoreGuiInset, "IgnoreGuiInset enabled")
check(window._settingsTab ~= nil, "settings tab built")
eq(window._activeTab, window._settingsTab, "settings tab selected while it is the only tab")
noErrors("creation")

--------------------------------------------------------------------------------
section("tabs")
--------------------------------------------------------------------------------

local main = window:CreateTab({ name = "Main", icon = 4483362458 })
local visuals = window:CreateTab("Visuals", "rbxassetid://1")
M.flush()
eq(window._activeTab, main, "first user tab auto-selected")
check(main.page.Visible and not window._settingsTab.page.Visible, "only the active page visible")
eq(#window._tabs, 3, "three tabs")
check(main.button.LayoutOrder < window._settingsTab.button.LayoutOrder, "settings tab sorted last")
check(window:Navigate("Visuals"), "navigate by name")
eq(window._activeTab, visuals, "visuals active")
M.click(main.button)
eq(window._activeTab, main, "clicking tab button selects it")
check(not window:Navigate("Nope"), "navigate to missing tab returns false")

--------------------------------------------------------------------------------
section("button")
--------------------------------------------------------------------------------

local presses = 0
local button = main:CreateButton({ name = "Press", description = "does a thing", callback = function() presses = presses + 1 end })
M.click(hitbox(button.root))
eq(presses, 1, "button callback fired on click")
button:Lock("nope")
M.click(hitbox(button.root))
eq(presses, 1, "locked button ignores clicks")
check(button:IsLocked(), "IsLocked true")
eq(button._desc.Text, "nope", "lock reason replaces description")
button:Unlock()
eq(button._desc.Text, "does a thing", "description restored on unlock")
M.click(hitbox(button.root))
eq(presses, 2, "unlocked button works")

--------------------------------------------------------------------------------
section("toggle")
--------------------------------------------------------------------------------

local toggleValues = {}
local toggle = main:CreateToggle({ name = "Auto Sprint", flag = "AutoSprint", callback = function(v) table.insert(toggleValues, v) end })
eq(toggle.value, false, "default false")
M.click(hitbox(toggle.root))
eq(toggle.value, true, "click toggles on")
eq(toggleValues[1], true, "callback received true")
eq(toggle._fill.BackgroundColor3, window.Theme.Accent, "fill uses accent when on")
toggle:Set(false, true)
eq(toggle.value, false, "Set silently")
eq(#toggleValues, 1, "skipCallback honoured")
toggle:Set(true)
eq(#toggleValues, 2, "Set fires callback")
check(main.CreateSwitch ~= nil, "CreateSwitch alias exists")
eq(window.Flags.AutoSprint, true, "Flags read")
window.Flags.AutoSprint = false
eq(toggle.value, false, "Flags write updates element")
eq(toggleValues[#toggleValues], false, "Flags write fires callback")

--------------------------------------------------------------------------------
section("slider")
--------------------------------------------------------------------------------

local sliderCalls = {}
local slider = main:CreateSlider({
	name = "FOV", range = { 70, 120 }, increment = 1, value = 90, suffix = "°",
	callback = function(v, dragging) table.insert(sliderCalls, { v, dragging }) end,
})
eq(slider.value, 90, "initial value")
eq(slider._valueLabel.Text, "90°", "value label with suffix")
local bar = slider._bar
local barHit = hitbox(bar)
local p, s = bar.AbsolutePosition, bar.AbsoluteSize
check(s.X > 0, "slider bar has width in mock layout")
M.drag(barHit, Vector2.new(p.X + 1, p.Y + 2), Vector2.new(p.X + s.X / 2, p.Y + 2))
eq(slider.value, 95, "drag to middle -> 95")
local last = sliderCalls[#sliderCalls]
eq(last[2], false, "final callback has dragging=false")
check(sliderCalls[1][2] == true, "intermediate callbacks have dragging=true")
M.drag(barHit, Vector2.new(p.X, p.Y), Vector2.new(p.X + s.X + 50, p.Y))
eq(slider.value, 120, "drag past end clamps to max")
slider:Set(73.4)
eq(slider.value, 73, "Set snaps to increment")
slider:Set(1000, true)
eq(slider.value, 120, "Set clamps")
local fine = main:CreateSlider({ name = "Smooth", range = { 0, 1 }, increment = 0.05, value = 0.33 })
eq(fine.value, 0.35, "decimal increment snaps")
eq(fine._valueLabel.Text, "0.35", "decimal formatting")
local odd = main:CreateSlider({ name = "Odd", range = { 0, 10 }, increment = 3, value = 10 })
eq(odd.value, 10, "max reachable even off-step")
local minimal = main:CreateSlider({ name = "Minimal", minimal = true })
check(minimal.row == nil and minimal._valueLabel == nil, "minimal slider has no label row")

--------------------------------------------------------------------------------
section("dropdown")
--------------------------------------------------------------------------------

local picked = { n = 0 }
local dropdown = main:CreateDropdown({
	name = "Mode", options = { "Fast", "Balanced", "Safe" }, value = "Balanced",
	callback = function(v) picked.n = picked.n + 1 picked[picked.n] = v end,
})
eq(dropdown.value[1], "Balanced", "initial value table")
eq(dropdown._display.Text, "Balanced", "display text")
M.click(hitbox(dropdown._box))
check(dropdown._open, "dropdown opened")
local list = window._overlay:FindFirstChild("DropdownList")
check(list ~= nil, "list rendered in overlay")
local fast = list and M.find(list, function(d) return d.ClassName == "TextButton" and d.Name == "Fast" end)
check(fast ~= nil, "option button exists")
if fast then M.click(fast) end
eq(dropdown.value[1], "Fast", "option selected")
eq(picked[picked.n], "Fast", "single callback gets string")
check(not dropdown._open, "single select closes list")
eq(window._overlay:FindFirstChild("DropdownList"), nil, "list destroyed")

M.click(hitbox(dropdown._box))
check(dropdown._open, "reopened")
M.clickAt(Vector2.new(5, 5))
check(not dropdown._open, "outside click closes")

dropdown:Refresh({ "Fast", "Other" })
eq(dropdown.value[1], "Fast", "refresh keeps valid selection")
local callsBefore = picked.n
dropdown:Refresh({ "A", "B" })
eq(#dropdown.value, 0, "refresh drops removed selection")
eq(picked.n, callsBefore + 1, "callback fired after selection cleared")
eq(picked[picked.n], nil, "callback received nil")
dropdown:Add("C")
eq(#dropdown.options, 3, "Add option")
dropdown:Set("C")
eq(dropdown.value[1], "C", "Set by string")
dropdown:Remove("C")
eq(#dropdown.value, 0, "Remove clears selection")
eq(#dropdown.options, 2, "Remove option")
dropdown:Set("Missing")
eq(#dropdown.value, 0, "Set to unknown option ignored")

local multiPicked
local multi = main:CreateDropdown({
	name = "Targets", options = { "Head", "Torso", "Legs" }, multiSelect = true, value = { "Legs" },
	callback = function(v) multiPicked = v end,
})
M.click(hitbox(multi._box))
local multiList = window._overlay:FindFirstChild("DropdownList")
M.click(M.find(multiList, function(d) return d.Name == "Head" and d.ClassName == "TextButton" end))
check(multi._open, "multi select stays open")
eq(type(multiPicked), "table", "multi callback receives table")
eq(table.concat(multiPicked, ","), "Head,Legs", "multi values ordered like options")
M.click(M.find(window._overlay, function(d) return d.Name == "Legs" and d.ClassName == "TextButton" end))
eq(table.concat(multi.value, ","), "Head", "clicking selected option deselects")
eq(multi._display.Text, "Head", "multi display")
M.press("Escape")
M.clickAt(Vector2.new(1, 1))

local many = {}
for i = 1, 20 do many[i] = "Option " .. i end
local big = main:CreateDropdown({ name = "Big", options = many, placeholder = "Pick one" })
eq(big._display.Text, "Pick one", "placeholder shown")
M.click(hitbox(big._box))
local bigList = window._overlay:FindFirstChild("DropdownList")
local search = M.find(bigList, function(d) return d.ClassName == "TextBox" end)
check(search ~= nil, "search box for long lists")
search.Text = "option 1"
M.flush()
local shown = M.findAll(bigList, function(d) return d.ClassName == "TextButton" end)
eq(#shown, 11, "search filters (1, 10-19)")
M.clickAt(Vector2.new(1, 1))

--------------------------------------------------------------------------------
section("input")
--------------------------------------------------------------------------------

local committed
local input = main:CreateInput({ name = "Server", value = "My Server", placeholder = "type", clearOnFocus = true, callback = function(t) committed = t end })
eq(input._box.Text, "My Server", "initial text")
eq(input._box.PlaceholderText, "type", "placeholder")
M.focus(input._box)
eq(input._box.Text, "", "clearOnFocus clears")
input._box.Text = "Lobby"
M.unfocus(true)
eq(committed, "Lobby", "commit on focus lost")
eq(input.value, "Lobby", "value updated")

local numeric = main:CreateInput({ name = "Amount", numeric = true, value = "5" })
M.typeInto(numeric._box, "abc")
eq(numeric.value, "5", "numeric rejects text")
eq(numeric._box.Text, "5", "numeric reverts field")
M.typeInto(numeric._box, "12.5")
eq(numeric.value, "12.5", "numeric accepts number")

--------------------------------------------------------------------------------
section("keybind")
--------------------------------------------------------------------------------

local fired, changedTo = 0, nil
local bind = main:CreateKeybind({ name = "Sprint", value = Enum.KeyCode.LeftShift, callback = function() fired = fired + 1 end, onChanged = function(k) changedTo = k end })
eq(bind._button.Text, "[LSHIFT]", "key label")
M.press("LeftShift")
eq(fired, 1, "callback on press")
M.focus(input._box)
M.press("LeftShift")
eq(fired, 1, "ignored while typing")
M.unfocus(false)
M.click(bind._button)
eq(bind._button.Text, "[...]", "listening state")
M.press("E")
eq(bind.value, Enum.KeyCode.E, "rebound to E")
eq(changedTo, Enum.KeyCode.E, "onChanged fired")
eq(fired, 1, "binding does not fire callback")
M.press("E")
eq(fired, 2, "new key fires")
M.click(bind._button)
M.mouseDown("MouseButton2")
eq(bind.value, Enum.UserInputType.MouseButton2, "mouse button bind")
eq(bind._button.Text, "[MB2]", "mouse label")
M.mouseDown("MouseButton2")
eq(fired, 3, "mouse bind fires")
bind:Set("RightShift")
eq(bind.value, Enum.UserInputType.MouseButton2, "menu key refused")
check(warned("menu key"), "warned about menu key")
bind:Set("Q", true)
eq(bind.value, Enum.KeyCode.Q, "Set by string")
M.click(bind._button)
M.press("Backspace")
eq(bind.value, nil, "backspace clears")
eq(bind._button.Text, "[NONE]", "none label")
M.click(bind._button)
M.press("Escape")
eq(bind._button.Text, "[NONE]", "escape cancels")

local holdStates = {}
local hold = main:CreateKeybind({ name = "Aim", value = "MB2", hold = true, holdThreshold = 0.3, callback = function(h) table.insert(holdStates, h) end })
eq(hold.value, Enum.UserInputType.MouseButton2, "MB2 alias parsed")
M.mouseDown("MouseButton2")
M.advance(0.1)
M.mouseUp("MouseButton2")
eq(#holdStates, 0, "quick tap ignored in hold mode")
M.mouseDown("MouseButton2")
M.advance(0.4)
eq(holdStates[1], true, "held past threshold")
M.mouseUp("MouseButton2")
eq(holdStates[2], false, "release reported")

--------------------------------------------------------------------------------
section("color picker")
--------------------------------------------------------------------------------

local colorCalls = {}
local picker = main:CreateColorPicker({ name = "Highlight", color = "#FF8800", alpha = 0.5, flag = "Overlay", callback = function(c, a) table.insert(colorCalls, { c, a }) end })
eq(picker.value:ToHex(), "FF8800", "hex initial colour")
eq(picker.alpha, 0.5, "initial alpha")
eq(picker._swatch.BackgroundTransparency, 0.5, "swatch shows alpha")
picker:Set(Color3.fromRGB(255, 0, 0))
eq(#colorCalls, 1, "Set fires")
eq(colorCalls[1][2], 0.5, "callback gets alpha")
picker:Set(Color3.fromRGB(0, 255, 0), true)
eq(#colorCalls, 1, "silent Set")
picker:SetAlpha(0.25)
eq(picker.alpha, 0.25, "SetAlpha")
M.click(hitbox(picker.row))
check(picker._open, "picker opened")
local pop = window._overlay:FindFirstChild("ColorPicker")
check(pop ~= nil, "picker popover rendered")
local hexBox = M.find(pop, function(d) return d.ClassName == "TextBox" end)
eq(hexBox.Text, "#00FF00", "hex box shows colour")
M.typeInto(hexBox, "0000ff")
eq(picker.value:ToHex(), "0000FF", "hex entry applies")
local hueFrame = M.find(pop, function(d) return d.ClassName == "Frame" and d:FindFirstChildOfClass("UIGradient") and d:FindFirstChildOfClass("UIGradient").Rotation == 90 and d.Size == UDim2.new(1, -2, 1, -2) and d.Parent.Size == UDim2.fromOffset(14, 152) end)
check(hueFrame ~= nil, "hue bar found")
if hueFrame then
	local hp, hs = hueFrame.AbsolutePosition, hueFrame.AbsoluteSize
	M.drag(hitbox(hueFrame), Vector2.new(hp.X + 2, hp.Y + 1), Vector2.new(hp.X + 2, hp.Y + hs.Y * 0.5))
	local h = picker.value:ToHSV()
	check(math.abs(h - 0.5) < 0.02, "hue drag sets hue ~0.5 (got " .. h .. ")")
end
M.clickAt(Vector2.new(1, 1))
check(not picker._open, "picker closes on outside click")
eq(window.Flags.Overlay, picker.value, "flag returns Color3")

--------------------------------------------------------------------------------
section("stat / progress / console / text / divider")
--------------------------------------------------------------------------------

local stat = main:CreateStat({ name = "Revenue", prefix = "$", value = 12400 })
eq(stat._number.Text, "$12400", "stat value")
stat:Set(stat.value + 620)
M.flush()
eq(stat._number.Text, "$13020", "stat eased to new value")
eq(stat._change.Text, "+5%", "percentage change")
stat:ResetBaseline()
eq(stat._change.Text, "0%", "baseline reset")
local abs = main:CreateStat({ name = "Kills", value = 10, changeMode = "absolute", compact = true, display = "change" })
abs:Set(7)
eq(abs._number.Text, "-3", "compact absolute change")

local prog = main:CreateProgress({ name = "Download", range = { 0, 100 }, value = 35 })
eq(prog._readout.Text, "35%", "progress percent")
prog:Set(80)
eq(prog:GetPercentage(), 0.8, "GetPercentage")
eq(prog:Get(), 80, "Get")
prog:SetRange(0, 200)
eq(prog._readout.Text, "40%", "SetRange")
prog:SetText("custom")
eq(prog._readout.Text, "custom", "SetText")
prog:SetText()
eq(prog._readout.Text, "40%", "SetText() restores")
local steps = main:CreateProgress({ name = "Setup", steps = 5, value = 2 })
eq(steps.max, 5, "steps default range")
eq(steps._segments[2].BackgroundColor3, window.Theme.Accent, "segment 2 filled")
eq(steps._segments[3].BackgroundColor3, window.Theme.Element, "segment 3 empty")
local sweep = main:CreateProgress({ name = "Sync", indeterminate = true })
check(sweep._sweep ~= nil, "sweep running")
M.advance(0.2)
sweep:Set(1)
check(sweep._sweep == nil and not sweep.indeterminate, "Set ends sweep")
local files = main:CreateProgress({ name = "Files", range = { 0, 200 }, value = 50, format = function(v, _, max) return string.format("%d of %d files", v, max) end })
eq(files._readout.Text, "50 of 200 files", "format function")

local console = main:CreateConsole({ name = "Log", follow = true, maxLines = 3, height = 20 })
eq(console.height, 48, "min height enforced")
console:Append("one")
console:Append("two\nthree")
console:Append("four")
eq(console:Get(), "two\nthree\nfour", "maxLines trims oldest")
check(console:Copy(), "copy succeeds")
eq(M.clipboard, "two\nthree\nfour", "clipboard content")
console:Clear()
eq(console:Get(), "", "clear")
console:Set("ready")
eq(console._body.Text, "ready", "set body")
console:SetHeight(200)
eq(console._slotFrame.Size.Y.Offset, 200, "SetHeight")
M.flush()

local text = main:CreateText({ name = "Status", text = "Waiting." })
text:Set("Connected.")
eq(text._body.Text, "Connected.", "text Set")
text:SetTitle("")
check(not text._titleRow.Visible, "empty title hidden")
local label = main:CreateLabel("plain label")
eq(label._body.Text, "plain label", "CreateLabel")
local para = main:CreateParagraph({ Title = "T", Content = "C" })
para:Set({ Title = "T2", Content = "C2" })
eq(para._title.Text, "T2", "paragraph Set table title")
eq(para._body.Text, "C2", "paragraph Set table content")

local divider = main:CreateDivider()
eq(divider.text, "", "empty divider")
divider:Set("advanced")
eq(divider._word.Text, "advanced", "divider word")
check(divider._left.Size.X.Offset < 0, "lines leave room for word")
divider:Set("")
check(not divider._word.Visible, "word hidden when cleared")
local spacer = main:CreateDivider({ line = false, spacing = 20 })
check(not spacer._left.Visible, "line=false hides rule")

--------------------------------------------------------------------------------
section("sections, groups, ordering")
--------------------------------------------------------------------------------

local looseTab = window:CreateTab({ name = "Loose" })
looseTab:CreateToggle({ name = "Loose" })
check(looseTab.columns[1].frame.Visible and not looseTab.columns[2].frame.Visible, "single implicit box uses one column")
eq(looseTab.columns[1].frame.Size.X.Scale, 1, "lone column spans full width")
local masonry = looseTab:CreateSection("Next")
eq(masonry.column, looseTab.columns[2], "next section goes to the emptier column")

local tab = window:CreateTab({ name = "Layout" })
local left = tab:CreateSection({ name = "Aimbot", icon = 5 })
eq(left.column, tab.columns[1], "first section starts left")
local inLeft = tab:CreateToggle({ name = "Enabled" })
eq(inLeft.holder, left, "elements follow latest section")
local right = tab:CreateSection("Visuals")
eq(right.column, tab.columns[2], "auto-balanced into second column")
check(tab.columns[2].frame.Visible, "second column shown")
eq(tab.columns[1].frame.Size.X.Scale, 0.5, "columns split")
local forced = tab:CreateSection({ name = "Forced", side = "left" })
eq(forced.column, tab.columns[1], "side option respected")
left:CreateButton({ name = "Late" })
eq(#left.children, 2, "section handle can add later")

local row = right:CreateGroup({ direction = "row" })
local a = row:CreateButton({ name = "A" })
local b = row:CreateToggle({ name = "B" })
eq(a.root.Size.X.Scale, 0.5, "row splits two children")
local c = row:CreateStat({ name = "C", value = 1 })
check(c.compact, "stats forced compact in rows")
eq(a.root.Size.X.Scale, 1 / 3, "row splits three children")
local d = row:CreateButton({ name = "D" })
eq(d.root.Size.X.Scale, 1 / 3, "fourth wraps (3 per row)")
local nope = row:CreateInput({ name = "nope" })
eq(nope, nil, "input refused in row")
check(warned("cannot be placed in a row"), "row warning")
local col = right:CreateGroup({ direction = "vertical" })
local inner = col:CreateGroup({ direction = "horizontal" })
inner:CreateButton({ name = "Nested" })
col:CreateDropdown({ name = "In column", options = { "x" } })
col:CreateSection("Sub header")

local s1 = forced:CreateToggle({ name = "one" })
local s2 = forced:CreateToggle({ name = "two" })
local s3 = forced:CreateToggle({ name = "three" })
s3:MoveToTop()
eq(s3.root.LayoutOrder, 1, "MoveToTop")
eq(s1.root.LayoutOrder, 2, "others shift")
s3:MoveDown()
eq(s3.root.LayoutOrder, 2, "MoveDown")
s3:MoveToBottom()
eq(s3.root.LayoutOrder, 3, "MoveToBottom")
s3:MoveUp()
eq(s3.root.LayoutOrder, 2, "MoveUp")
s2:Remove()
eq(#forced.children, 2, "Remove detaches")
eq(window._elements["two"], nil, "Remove unregisters flag")
forced:Set("Renamed")
eq(forced._title.Text, "Renamed", "section rename")
right:Remove()
check(not tab.columns[2].frame.Visible, "removing section collapses column")
noErrors("layout")

--------------------------------------------------------------------------------
section("flags, saving and loading")
--------------------------------------------------------------------------------

local dupA = main:CreateToggle({ name = "Same" })
local dupB = main:CreateToggle({ name = "Same" })
eq(dupB.flag, "Same (2)", "derived flags are unique")
local forget = main:CreateToggle({ name = "Secret", forgetState = true, value = true })

toggle:Set(true)
slider:Set(100)
multi:Set({ "Head", "Torso" })
input:Set("Saved text")
picker:Set(Color3.fromRGB(10, 20, 30))
picker:SetAlpha(0.75)
local holdKey = hold.value
check(window:Save(), "Save returns true")
local folder, path = window:GetPath()
eq(folder, "Onyx/Configurations/suite", "config folder")
eq(path, "Onyx/Configurations/suite/test.json", "config path")
check(M.files[path] ~= nil, "file written")
check(not string.find(M.files[path], "Secret", 1, true), "forgetState not saved")

check(window:Save("PvP Loadout"), "named save")
local configs = window:ListConfigs()
eq(#configs, 2, "two configs listed")
eq(configs[1], "PvP Loadout", "listfiles backslash paths parsed")

toggle:Set(false)
slider:Set(70)
check(window:Load("PvP Loadout"), "Load named")
eq(toggle.value, true, "toggle restored")
eq(slider.value, 100, "slider restored")
eq(table.concat(multi.value, ","), "Head,Torso", "multi restored")
eq(input.value, "Saved text", "input restored")
eq(picker.value:ToHex(), "0A141E", "colour restored")
eq(picker.alpha, 0.75, "alpha restored")
eq(hold.value, holdKey, "keybind restored")
check(window:DeleteConfig("PvP Loadout"), "DeleteConfig")
eq(#window:ListConfigs(), 1, "deleted")
check(not window:Load("missing"), "Load missing returns false")
check(not window:Set("NoSuchFlag", 1), "Set unknown flag returns false")
eq(window:Get("FOV"), 100, "Get by derived flag")

local seen = 0
for flag, value in pairs(window.Flags) do seen = seen + 1 end
check(seen > 10, "Flags iterable (" .. seen .. ")")

-- autosave debounce
toggle:Set(false)
M.files[path] = nil
M.advance(1)
check(M.files[path] ~= nil, "autosave wrote after debounce")

--------------------------------------------------------------------------------
section("autoload into a new window")
--------------------------------------------------------------------------------

window:Unload()
check(window.unloaded, "unloaded flag")
eq(gui.Parent, nil, "gui destroyed")
noErrors("unload")

local restored
local window2 = Onyx:CreateWindow({ name = "Onyx Test", configuration = { autoLoad = true, fileName = "test", customFolder = "suite" } })
local t2 = window2:CreateTab("Main")
local slider2 = t2:CreateSlider({ name = "FOV", range = { 70, 120 }, value = 90, callback = function(v) restored = v end })
eq(slider2.value, 90, "value before deferred restore")
M.flush()
eq(slider2.value, 100, "autoload restored on creation")
eq(restored, 100, "autoload fires callback")
local late = t2:CreateToggle({ name = "Auto Sprint", flag = "AutoSprint" })
M.flush()
eq(late.value, false, "late element restored")
window2:Unload()

--------------------------------------------------------------------------------
section("messages, tags, visibility, themes, locale")
--------------------------------------------------------------------------------

local w = Onyx:CreateWindow({ name = "Msg", sidebarLayout = true, profile = "Premium", theme = "frost", settingsTab = false })
local wt = w:CreateTab({ name = "Home", icon = 1 })
local railSection = w:CreateSection("Combat")
check(railSection.Remove ~= nil, "rail section handle")
eq(w._settingsTab, nil, "settings tab disabled")
eq(w._profileLabel.Text, "Premium", "profile line")
w:SetProfile()
check(not w._profileLabel.Visible, "SetProfile() clears")

local n = w:Notify({ title = "Hello", content = "World", duration = 1 })
check(w._notifyList:FindFirstChild("Notification") ~= nil, "notification shown")
M.advance(1.2)
M.flush()
eq(w._notifyList:FindFirstChild("Notification"), nil, "notification expired")
for i = 1, 8 do w:Notify({ title = "N" .. i, duration = 30 }) end
eq(#w._notifications, 6, "stack capped at 6")
M.flush()
w:Notify({ title = "icon", icon = 125823673784681 })
check(M.find(w._notifyList, function(d) return d.ClassName == "ImageLabel" and d.Image == "rbxassetid://125823673784681" end) ~= nil, "large asset id formatted")

w:Toast({ title = "Saved", subtitle = "ok", avatar = 1, position = "Bottom", minWidth = 200, duration = 1 })
check(w._toastBottom:FindFirstChild("Toast") ~= nil, "bottom toast")
M.advance(1.5)
eq(w._toastBottom:FindFirstChild("Toast"), nil, "toast expired")

local chose = false
local popup = w:Popup({
	title = "Reset?", subtitle = "Sure?", content = "This clears things",
	boxes = { { title = "Box", description = "desc", icon = 3 } },
	options = { { text = "Cancel" }, { text = "Reset", style = "danger", callback = function() chose = true end } },
})
local resetButton = M.byText(w._popupLayer, "Reset")
check(resetButton ~= nil, "popup option rendered")
M.click(hitbox(resetButton.Parent.Parent))
check(chose, "popup option callback")
M.flush()
eq(#w._popups, 0, "popup closed after option")
local stuck = w:Popup({ title = "Saving", dismissable = false })
M.press("Escape")
eq(#w._popups, 1, "non-dismissable ignores Escape")
stuck:Close()
eq(#w._popups, 0, "Close()")
w:Popup({ title = "Esc" })
M.press("Escape")
eq(#w._popups, 0, "Escape dismisses")

local tag = w:CreateTag({ text = "us-en", color = Color3.fromRGB(255, 175, 15), order = 1 })
tag:Set({ text = "live", color = Color3.fromRGB(80, 200, 120) })
eq(M.byText(w._tagList, "live") ~= nil, true, "tag text updated")
tag:SetIcon(4)
tag:Remove()
eq(M.byText(w._tagList, "live"), nil, "tag removed")

w:Hide()
check(not w._main.Visible and w._pill.Visible, "hidden shows pill")
M.press("RightShift")
check(w._main.Visible, "menu key shows")
M.press("RightShift")
check(not w._main.Visible, "menu key hides")
M.click(hitbox(w._pill))
check(w._main.Visible, "pill click shows")
w:ToggleMinimise()
check(w.minimised, "minimised")
eq(w._main.Size.Y.Offset, 32, "minimised height")
w:ToggleMinimise()
eq(w._main.Size.Y.Offset, w._size.Y, "restored height")

local tToggle = wt:CreateToggle({ name = "Themed", value = true })
w:ChangeTheme("ember")
eq(tToggle._fill.BackgroundColor3, Color3.fromRGB(255, 124, 50), "theme change repaints state colours")
w:ChangeTheme({ AccentColor = Color3.fromRGB(1, 2, 3) })
eq(w.Theme.Accent, Color3.fromRGB(1, 2, 3), "partial theme via alias key")
eq(w.Theme.Background, Color3.fromRGB(14, 14, 14), "partial overlay keeps other keys")
w:ChangeTheme("nonsense")
check(warned("unknown theme"), "unknown theme warns")

w:RegisterTranslations({ ["en-us"] = { Home = "Start" } })
eq(wt._buttonLabel.Text, "Start", "translation applied")
w:SetLocale("fr")
eq(wt._buttonLabel.Text, "Home", "locale switch falls back")
w:SetTranslator(function(s) return string.upper(s) end)
eq(wt._buttonLabel.Text, "HOME", "custom translator")
w:SetTranslator(nil)

wt:Remove()
eq(#w._tabs, 0, "tab removed")
w:Unload()
noErrors("messages")

--------------------------------------------------------------------------------
section("custom theme + settings tab interactions")
--------------------------------------------------------------------------------

local cw = Onyx:CreateWindow({ name = "Custom", theme = { AccentColor = Color3.fromRGB(200, 0, 0) }, configuration = { fileName = "custom" } })
local themeDrop = cw._themeDropdown
eq(themeDrop.value[1], "custom", "custom theme listed")
themeDrop:Set("rose")
eq(cw.Theme.Name, "rose", "settings dropdown switches theme")
themeDrop:Set("custom")
eq(cw.Theme.Accent, Color3.fromRGB(200, 0, 0), "custom theme restorable")
cw:ChangeTheme("cobalt")
eq(themeDrop.value[1], "cobalt", "dropdown follows ChangeTheme")
local menuBind = cw._elements.OnyxMenuKey
menuBind:Set(Enum.KeyCode.Insert)
eq(cw.toggleKey, Enum.KeyCode.Insert, "menu key rebind")
M.press("Insert")
check(not cw._main.Visible, "new menu key hides")
M.press("Insert")
check(cw._main.Visible, "new menu key shows")
local cfgSection = cw._settingsTab.columns[2].children[1]
check(cfgSection ~= nil and cfgSection.name == "Configurations", "configurations section exists")
local nameBox = cfgSection.children[1]
M.typeInto(nameBox._box, "mine")
local saveBtn = M.byText(cfgSection.root, "Save")
M.click(hitbox(saveBtn.Parent.Parent))
check(M.files["Onyx/Configurations/mine.json"] ~= nil, "settings Save button writes config")
eq(cfgSection.children[2].options[1], "mine", "saved list refreshed")
cw:Unload()
noErrors("settings")

--------------------------------------------------------------------------------
section("legacy option names (PascalCase)")
--------------------------------------------------------------------------------

local Lib = Onyx
local Window = Lib:CreateWindow({
	Name = "Example Window",
	LoadingTitle = "Loading",
	LoadingSubtitle = "please wait",
	ConfigurationSaving = { Enabled = true, FolderName = "Hub", FileName = "Big Hub" },
	Discord = { Enabled = false },
	KeySystem = false,
})
local Tab = Window:CreateTab("Tab Example", 4483362458)
local Section = Tab:CreateSection("Section Example")
local log = {}
Tab:CreateButton({ Name = "Button Example", Callback = function() log.button = true end })
local Toggle = Tab:CreateToggle({ Name = "Toggle Example", CurrentValue = false, Flag = "Toggle1", Callback = function(v) log.toggle = v end })
local Slider = Tab:CreateSlider({ Name = "Slider Example", Range = { 0, 100 }, Increment = 10, Suffix = "Bananas", CurrentValue = 10, Flag = "Slider1", Callback = function(v) log.slider = v end })
local Dropdown = Tab:CreateDropdown({ Name = "Dropdown Example", Options = { "Option 1", "Option 2" }, CurrentOption = { "Option 1" }, MultipleOptions = false, Flag = "Dropdown1", Callback = function(v) log.dropdown = v end })
local Input = Tab:CreateInput({ Name = "Input Example", CurrentValue = "", PlaceholderText = "Input Placeholder", RemoveTextAfterFocusLost = true, Flag = "Input1", Callback = function(t) log.input = t end })
local Keybind = Tab:CreateKeybind({ Name = "Keybind Example", CurrentKeybind = "Q", HoldToInteract = false, Flag = "Keybind1", Callback = function() log.keybind = true end })
local ColorPicker = Tab:CreateColorPicker({ Name = "Color Picker", Color = Color3.fromRGB(255, 255, 255), Flag = "ColorPicker1", Callback = function(c) log.color = c end })
local Label = Tab:CreateLabel("Label Example", 4483362458)
local Paragraph = Tab:CreateParagraph({ Title = "Paragraph Example", Content = "Paragraph Example" })
local Divider = Tab:CreateDivider()
Lib:Notify({ Title = "Notification Title", Content = "Notification Content", Duration = 6.5, Image = 4483362458 })

M.click(hitbox(Tab._current.children[1].root))
check(log.button, "legacy button")
Toggle:Set(true)
eq(log.toggle, true, "legacy toggle Set")
eq(Toggle.CurrentValue, true, "legacy CurrentValue mirror")
Slider:Set(47)
eq(log.slider, 50, "legacy slider increment")
eq(Slider._valueLabel.Text, "50Bananas", "legacy suffix")
eq(Dropdown.value[1], "Option 1", "legacy CurrentOption table")
Dropdown:Set({ "Option 2" })
eq(log.dropdown, "Option 2", "legacy dropdown set")
eq(Input._box.PlaceholderText, "Input Placeholder", "legacy placeholder")
M.typeInto(Input._box, "hello")
eq(log.input, "hello", "legacy input callback")
eq(Input._box.Text, "", "RemoveTextAfterFocusLost clears")
eq(Keybind.value, Enum.KeyCode.Q, "legacy keybind string")
M.press("Q")
check(log.keybind, "legacy keybind fires")
ColorPicker:Set(Color3.fromRGB(1, 1, 1))
check(log.color ~= nil, "legacy color callback")
Label:Set("Label updated")
eq(Label._body.Text, "Label updated", "legacy label Set")
eq(Lib.Flags.Toggle1, true, "library-level Flags")
eq(Window._config.customFolder, "Hub", "legacy folder")
eq(Window._config.autoLoad, false, "legacy waits for LoadConfiguration")
check(Window:Save(), "legacy save")
Toggle:Set(false)
check(Lib:LoadConfiguration(), "LoadConfiguration")
eq(Toggle.value, true, "LoadConfiguration restores")
Lib:SetVisibility(false)
check(not Lib:IsVisible(), "SetVisibility(false)")
Lib:SetVisibility(true)
check(Lib:IsVisible(), "SetVisibility(true)")
Lib:Destroy()
eq(#Onyx.Windows, 0, "Destroy unloads every window")
noErrors("legacy")

--------------------------------------------------------------------------------
section("PC: default RightShift toggle")
--------------------------------------------------------------------------------

local pc = Onyx:CreateWindow({ name = "pc" }) -- no toggleKey given
M.flush()
check(not pc._mobile, "mouse + keyboard is not treated as mobile")
eq(pc.toggleKey, Enum.KeyCode.RightShift, "default menu key is RightShift")
check(not pc._pill.Visible, "launcher hidden while the menu is open on PC")
eq(pc._scale, 1, "no scaling on a 1280x720 screen")
M.press("RightShift")
check(not pc._main.Visible and not pc.visible, "RightShift hides")
check(pc._pill.Visible, "launcher appears while hidden on PC")
eq(pc._pillLabel.Text, "pc  [RSHIFT]", "launcher shows the key")
M.press("RightShift")
check(pc._main.Visible, "RightShift shows again")
check(not pc._pill.Visible, "launcher hides again")
M.press("LeftShift")
check(pc._main.Visible, "other keys do not toggle")
local pcInput = pc:CreateTab("t"):CreateInput({ name = "chat" })
M.focus(pcInput._box)
M.press("RightShift")
check(pc._main.Visible, "RightShift ignored while typing")
M.unfocus(false)
M.click(M.find(pc._main, function(d) return d.ClassName == "TextButton" and d.Text == "x" end))
check(not pc.visible, "close button hides")
check(M.byText(pc._notifyList, "Press RSHIFT to open it again.") ~= nil, "close hint names the key on PC")
M.click(hitbox(pc._pill))
check(pc.visible, "clicking the launcher reopens on PC")
pc:Unload()

--------------------------------------------------------------------------------
section("mobile")
--------------------------------------------------------------------------------

M.UIS.TouchEnabled, M.UIS.MouseEnabled, M.UIS.KeyboardEnabled = true, false, false
M.setViewport(Vector2.new(844, 390)) -- landscape phone
local mw = Onyx:CreateWindow({ name = "onyx" })
local mtab = mw:CreateTab("Main")
local msec = mtab:CreateSection("Combat")
local mToggle = msec:CreateToggle({ name = "Enabled" })
local mSlider = msec:CreateSlider({ name = "FOV", range = { 0, 100 }, value = 0 })
local mDrop = msec:CreateDropdown({ name = "Part", options = { "Head", "Torso" } })
M.flush()

check(mw._mobile, "touch-only device detected as mobile")
check(mw._pill.Visible, "launcher always visible on mobile")
eq(mw._pillLabel.Text, "onyx", "mobile launcher has no key hint")
check(mw._scale < 1, "window scaled down to fit the phone (" .. mw._scale .. ")")
eq(mw._uiScale.Scale, mw._scale, "UIScale applied")
check(math.abs(mw._scale - (390 - 16) / 440) < 1e-6, "scale fits the screen height")

-- Tap the launcher to hide / show (no keyboard needed)
local launcher = hitbox(mw._pill)
M.tap(launcher)
check(not mw.visible and not mw._main.Visible, "tap launcher hides the menu")
check(mw._pill.Visible, "launcher stays visible to reopen")
M.tap(launcher)
check(mw.visible and mw._main.Visible, "tap launcher shows the menu")

-- Dragging the launcher moves it without toggling
local before = mw._pill.AbsolutePosition
local c0 = M.center(launcher)
M.touchDrag(launcher, c0, Vector2.new(c0.X + 120, c0.Y + 80))
check(mw.visible, "dragging the launcher does not toggle")
local after = mw._pill.AbsolutePosition
check(math.abs(after.X - before.X - 120) < 1 and math.abs(after.Y - before.Y - 80) < 1, "launcher follows the finger")
M.touchDrag(launcher, M.center(launcher), Vector2.new(5000, 5000))
local edge = mw._pill.AbsolutePosition
check(edge.X + mw._pill.AbsoluteSize.X <= 844 + 0.5 and edge.Y + mw._pill.AbsoluteSize.Y <= 390 + 0.5, "launcher clamped on screen")

-- Header buttons by touch
local minus = mw._minimiseButton
eq(minus.Size.X.Offset, 28, "larger header buttons on mobile")
M.tap(minus)
check(mw.minimised, "tap minimise collapses the window")
M.tap(minus)
check(not mw.minimised, "tap again restores")
M.tap(M.find(mw._main, function(d) return d.ClassName == "TextButton" and d.Text == "x" end))
check(not mw.visible, "tap close hides")
check(M.byText(mw._notifyList, "Tap the onyx button to open it again.") ~= nil, "close hint mentions the button on mobile")
M.tap(launcher)
check(mw.visible, "reopened")

-- Toggle by tap
M.tap(hitbox(mToggle.row))
eq(mToggle.value, true, "tap toggles")

-- Slider by touch, and a second finger (joystick thumb) cannot hijack it
local bar = mSlider._bar
local bp, bs = bar.AbsolutePosition, bar.AbsoluteSize
local sliderHit = hitbox(bar)
check(sliderHit.Size.Y.Offset == 12, "slider hit area taller than the 10px bar")
local finger = M.finger(Vector2.new(bp.X + 1, bp.Y + 5))
M.touchBegin(finger, sliderHit)
check(not mtab.page.ScrollingEnabled, "page scrolling paused while dragging a slider")
local thumb = M.finger(Vector2.new(60, 300))
M.touchBegin(thumb)
M.touchMove(thumb, Vector2.new(bp.X + bs.X, 300))
eq(mSlider.value, 0, "second finger ignored")
M.touchMove(finger, Vector2.new(bp.X + bs.X / 2, bp.Y + 5))
eq(mSlider.value, 50, "slider follows its own finger")
M.touchEnd(thumb)
check(mw._drag ~= nil, "lifting the other finger does not end the drag")
M.touchEnd(finger, sliderHit)
check(mw._drag == nil, "drag ends with its finger")
check(mtab.page.ScrollingEnabled, "page scrolling restored")

-- Dragging the window by its header with a finger
local header = mw._main:FindFirstChild("Header", true) or M.find(mw._main, function(d) return d.Name == "Header" end)
local hp = M.center(header)
local mainBefore = mw._main.AbsolutePosition
M.touchDrag(header, hp, Vector2.new(hp.X - 40, hp.Y + 20))
local mainAfter = mw._main.AbsolutePosition
check(math.abs(mainAfter.X - mainBefore.X + 40) < 1 and math.abs(mainAfter.Y - mainBefore.Y - 20) < 1, "touch drag moves the window")

-- Dropdown by tap: taller rows, scaled list, tap outside closes
M.tap(hitbox(mDrop._box))
local mlist = mw._overlay:FindFirstChild("DropdownList")
check(mlist ~= nil, "dropdown opens by tap")
check(mlist:FindFirstChildOfClass("UIScale") ~= nil, "popover scaled with the window")
local headRow = M.find(mlist, function(d) return d.ClassName == "TextButton" and d.Name == "Head" end)
eq(headRow.Size.Y.Offset, 26, "touch-sized option rows")
M.tap(headRow)
eq(mDrop.value[1], "Head", "option chosen by tap")
M.tap(hitbox(mDrop._box))
M.tap(mw._overlay, Vector2.new(830, 380))
eq(mw._overlay:FindFirstChild("DropdownList"), nil, "tap outside closes")

-- Rotation to portrait refits
M.setViewport(Vector2.new(390, 844))
check(math.abs(mw._scale - (390 - 16) / 580) < 1e-6, "rotation rescales to the new width (" .. mw._scale .. ")")
local mp, ms = mw._main.AbsolutePosition, mw._main.AbsoluteSize
check(mp.X >= -0.5 and mp.Y >= -0.5, "window kept on screen after rotation")

-- Explicit overrides
local forced = Onyx:CreateWindow({ name = "forced", mobile = false, scale = 0.8 })
check(not forced._mobile and not forced._pill.Visible, "mobile = false hides launcher while open")
eq(forced._scale, 0.8, "scale option overrides auto-fit")
forced:Unload()
mw:Unload()
M.setViewport(Vector2.new(1280, 720))
M.UIS.TouchEnabled, M.UIS.MouseEnabled, M.UIS.KeyboardEnabled = false, true, true
noErrors("mobile")

--------------------------------------------------------------------------------
section("script status")
--------------------------------------------------------------------------------

local sw = Onyx:CreateWindow({ name = "hub", status = "working", statusNote = "all features up" })
M.flush()
local row = sw._statusRow
eq(row._value.Text, "WORKING", "status text in settings")
eq(row._value.TextColor3, Color3.fromRGB(112, 208, 92), "working is green")
eq(row._dot.BackgroundColor3, Color3.fromRGB(112, 208, 92), "dot matches")
eq(row._desc.Text, "all features up", "status note shown")
check(M.byText(sw._tagList, "working") ~= nil, "status tag in the header")
sw:SetStatus("updating", "fixing aimbot")
eq(row._value.TextColor3, Color3.fromRGB(255, 165, 40), "updating is orange")
eq(row._desc.Text, "fixing aimbot", "note updated")
sw:SetStatus("patched")
eq(row._value.TextColor3, Color3.fromRGB(226, 72, 72), "patched is red")
check(not row._desc.Visible, "no note hides the description")
eq(sw:GetStatus().state, "patched", "GetStatus")
sw:ChangeTheme("frost")
eq(row._value.TextColor3, Color3.fromRGB(226, 72, 72), "status colour survives a theme change")
sw:SetStatus({ text = "Beta", color = Color3.fromRGB(0, 120, 255), note = "testers only" })
eq(row._value.Text, "BETA", "custom status")
eq(row._value.TextColor3, Color3.fromRGB(0, 120, 255), "custom colour")
check(M.byText(sw._tagList, "beta") ~= nil and M.byText(sw._tagList, "working") == nil, "tag updated in place")
sw:SetStatus(nil)
check(not row.root.Visible, "SetStatus(nil) hides the row")
check(M.byText(sw._tagList, "beta") == nil, "and removes the tag")
sw:SetStatus("unknownthing")
check(warned("unknown status"), "unknown status warns")
sw:Unload()
local noTag = Onyx:CreateWindow({ name = "nt", status = "working", statusTag = false })
check(M.byText(noTag._tagList, "working") == nil, "statusTag = false keeps the header clean")
eq(noTag._statusRow._value.Text, "WORKING", "but settings still shows it")
noTag:Unload()
noErrors("status")

--------------------------------------------------------------------------------
section("status from a url")
--------------------------------------------------------------------------------

eq(Onyx.Status.Patched, "patched", "status constants")
local remote = { body = "updating: fixing esp" }
local fetched = 0
game.HttpGet = function(_, url)
	fetched = fetched + 1
	eq(url, "https://example.com/status.txt", "fetches the given url")
	return remote.body
end
local rw = Onyx:CreateWindow({ name = "remote", status = Onyx.Status.Working, statusUrl = "https://example.com/status.txt", statusRefresh = 30 })
M.flush()
eq(rw.status.state, "updating", "remote status overrides the local one")
eq(rw.status.note, "fixing esp", "note after the colon")
eq(rw._statusRow._value.TextColor3, Color3.fromRGB(255, 165, 40), "orange in settings")
remote.body = "PATCHED\nwait for the next update\nthanks"
M.advance(31)
eq(rw.status.state, "patched", "polling picks up the change")
eq(rw.status.note, "wait for the next update\nthanks", "note on the following lines")
remote.body = '{"status": "working", "note": "back up"}'
M.advance(31)
eq(rw.status.state, "working", "json format")
eq(rw.status.note, "back up", "json note")
local calls = fetched
M.advance(31)
eq(fetched, calls + 1, "keeps polling")
rw:Unload()
M.advance(61)
eq(fetched, calls + 1, "stops polling after unload")
remote.body = "  working  "
local once = Onyx:CreateWindow({ name = "once", statusUrl = "https://example.com/status.txt" })
M.flush()
eq(once.status.state, "working", "single fetch, whitespace trimmed")
eq(once.status.note, nil, "no note")
local before = fetched
M.advance(60)
eq(fetched, before, "no polling without statusRefresh")
once:Unload()
game.HttpGet = function() error("offline") end
local offline = Onyx:CreateWindow({ name = "offline", status = "working", statusUrl = "https://example.com/status.txt" })
M.flush()
eq(offline.status.state, "working", "falls back to the local status when the fetch fails")
check(warned("couldn't fetch status"), "warns when offline")
offline:Unload()
game.HttpGet = function() error("HttpGet unavailable in mock") end
noErrors("remote status")

--------------------------------------------------------------------------------
section("key system")
--------------------------------------------------------------------------------

local keyed, done
task.spawn(function()
	keyed = Onyx:CreateWindow({
		name = "locked hub",
		keySystem = { keys = { "ONYX-1234" }, note = "get a key in our discord", url = "https://example.com/key", fileName = "lockedhub" },
	})
	done = true
end)
M.flush()
check(not done, "CreateWindow waits for a key")
local prompt = M.find(M.CoreGui, function(d) return d.Name == "KeySystem" end)
check(prompt ~= nil, "key prompt shown")
local mainFrame = M.find(M.CoreGui, function(d) return d.Name == "Main" and d.Parent == prompt.Parent end)
check(mainFrame and not mainFrame.Visible, "menu hidden behind the prompt")
local keyBox = M.find(prompt, function(d) return d.Name == "Key" end)
local message = M.find(prompt, function(d) return d.Name == "Message" end)
M.press("RightShift")
check(not mainFrame.Visible, "menu key can't bypass the prompt")

M.click(hitbox(M.byText(prompt, "get key").Parent.Parent))
eq(M.clipboard, "https://example.com/key", "get key copies the link")
M.typeInto(keyBox, "wrong")
eq(message.Text, "invalid key", "wrong key rejected")
M.advance(0.2)
check(not done, "still waiting after a wrong key")
keyBox.Text = "  ONYX-1234 "
M.click(hitbox(M.byText(prompt, "check key").Parent.Parent))
eq(message.Text, "key accepted", "right key accepted (whitespace trimmed)")
M.advance(0.2)
check(done and keyed ~= nil, "CreateWindow returns after a valid key")
check(keyed._main.Visible and keyed.visible, "menu shown after the key")
eq(prompt.Parent, nil, "prompt removed")
eq(M.files["Onyx/Keys/lockedhub.txt"], "ONYX-1234", "key saved")
keyed:Unload()

-- saved key skips the prompt
local again
task.spawn(function()
	again = Onyx:CreateWindow({ name = "locked hub", keySystem = { keys = { "ONYX-1234" }, fileName = "lockedhub" } })
end)
M.flush()
check(again ~= nil, "saved key skips the prompt")
again:Unload()

-- custom validate function + closing the prompt
local seenKeys, closedDone = {}, false
local closedWindow
task.spawn(function()
	closedWindow = Onyx:CreateWindow({
		name = "fn hub",
		keySystem = { saveKey = false, validate = function(key) table.insert(seenKeys, key) return key == "letmein" end },
	})
	closedDone = true
end)
M.flush()
local prompt2 = M.find(M.CoreGui, function(d) return d.Name == "KeySystem" end)
M.typeInto(M.find(prompt2, function(d) return d.Name == "Key" end), "nope")
eq(seenKeys[1], "nope", "validate function called")
local windowsBefore = #Onyx.Windows
M.click(M.find(prompt2, function(d) return d.Name == "Close" end))
M.advance(0.2)
check(not closedDone, "closing the prompt parks the script")
eq(#Onyx.Windows, windowsBefore - 1, "closing unloads the window")

-- old style KeySystem = true + KeySettings
local legacy
task.spawn(function()
	legacy = Onyx:CreateWindow({ Name = "legacy", KeySystem = true, KeySettings = { Title = "legacy", Key = { "abc" }, SaveKey = false } })
end)
M.flush()
local prompt3 = M.find(M.CoreGui, function(d) return d.Name == "KeySystem" end)
M.typeInto(M.find(prompt3, function(d) return d.Name == "Key" end), "abc")
M.advance(0.2)
check(legacy ~= nil, "KeySettings tables work")
legacy:Unload()
noErrors("key system")

--------------------------------------------------------------------------------
section("notice + changelog")
--------------------------------------------------------------------------------

local cl = Onyx:CreateWindow({
	name = "news",
	notice = { title = "Heads up", content = "Servers restart at 6pm.", button = "ok" },
	changelog = {
		once = true,
		entries = {
			{ version = "1.2.0", date = "2026-10-08", changes = { "Added key system", "Fixed slider on mobile" } },
			{ version = "1.1.0", changes = { "Mobile support" } },
		},
	},
})
check(#cl._popups == 0, "popups wait until the script finished building")
M.flush()
eq(#cl._popups, 2, "changelog and notice shown on execute")
local layer = cl._popupLayer
check(M.byText(layer, "What's new") ~= nil, "changelog title")
check(M.byText(layer, "v1.2.0  2026-10-08") ~= nil, "version heading")
check(M.byText(layer, "- Added key system\n- Fixed slider on mobile") ~= nil, "change list")
check(M.byText(layer, "Servers restart at 6pm.") ~= nil, "notice content")
local newest = M.byText(layer, "v1.2.0  2026-10-08")
eq(newest.TextColor3, cl.Theme.Accent, "newest version highlighted")
M.press("Escape")
eq(#cl._popups, 1, "notice is on top and closes first")
M.click(hitbox(M.byText(layer, "Got it").Parent.Parent))
eq(#cl._popups, 0, "changelog closed")
eq(M.files["Onyx/Seen/news.txt"], "1.2.0", "seen version stored")
check(cl:ShowChangelog({ once = true, entries = { { version = "1.2.0" } } }) == nil, "once: same version not shown twice")
check(cl:ShowChangelog({ once = true, entries = { { version = "1.3.0", changes = { "x" } } } }) ~= nil, "new version shows again")
check(cl:ShowNotice("plain string notice") ~= nil, "ShowNotice accepts a string")
cl:Unload()
noErrors("changelog")

--------------------------------------------------------------------------------
section("live animation + leaks")
--------------------------------------------------------------------------------

local aw = Onyx:CreateWindow({ name = "Anim" })
local before = aw._accentGradient.Color.Keypoints[1].Value
M.advance(2)
local after = aw._accentGradient.Color.Keypoints[1].Value
check(before ~= after, "accent bar animates")
local handlers = #M.UIS.InputBegan.handlers
aw:Unload()
check(#M.UIS.InputBegan.handlers < handlers, "unload disconnects global input")
eq(#M.RunService.RenderStepped.handlers, 0, "no RenderStepped leaks")
eq(#M.UIS.InputBegan.handlers, 0, "no InputBegan leaks after all windows unloaded")
noErrors("final")

for _, w in ipairs(M.warnings) do print("  expected warning: " .. w) end
print(string.format("\n%d passed, %d failed, %d warnings", passed, failed, #M.warnings))
__FAILURES = failed
