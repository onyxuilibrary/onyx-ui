-- A strict, minimal Roblox runtime for exercising Onyx outside the engine.
-- Unknown properties, wrong value types and invalid enum items raise errors like the real engine.

local Mock = { warnings = {}, errors = {}, clock = 0 }
_G.__mock = Mock

local function classof(v)
	local mt = getmetatable(v)
	return mt and mt.__typeof
end

function typeof(v)
	return classof(v) or type(v)
end

function warn(...)
	local parts = {}
	for i = 1, select("#", ...) do parts[#parts + 1] = tostring(select(i, ...)) end
	local msg = table.concat(parts, " ")
	table.insert(Mock.warnings, msg)
	if Mock.echoWarnings then print("  [warn] " .. msg) end
end

math.clamp = function(x, a, b)
	assert(type(x) == "number" and type(a) == "number" and type(b) == "number", "math.clamp expects numbers")
	if a > b then error("math.clamp: max must be greater than or equal to min", 2) end
	return math.max(a, math.min(b, x))
end
math.round = function(x) return math.floor(x + 0.5) end
math.huge = math.huge

--------------------------------------------------------------------------------
-- Signals and scheduler
--------------------------------------------------------------------------------

local Signal = {}
Signal.__index = Signal
Signal.__typeof = "RBXScriptSignal"

function Signal.new() return setmetatable({ handlers = {} }, Signal) end

function Signal:Connect(fn)
	assert(type(fn) == "function", "Connect expects a function")
	local conn = setmetatable({ Connected = true }, { __typeof = "RBXScriptConnection" })
	local signal = self
	local entry = { fn = fn, conn = conn }
	table.insert(self.handlers, entry)
	function conn.Disconnect()
		conn.Connected = false
		for i, e in ipairs(signal.handlers) do
			if e == entry then table.remove(signal.handlers, i) break end
		end
	end
	return conn
end

function Signal:Once(fn)
	local c
	c = self:Connect(function(...) c.Disconnect() fn(...) end)
	return c
end

function Signal:Fire(...)
	local list = {}
	for i, e in ipairs(self.handlers) do list[i] = e end
	for _, e in ipairs(list) do
		if e.conn.Connected then
			local ok, err = xpcall(e.fn, debug.traceback, ...)
			if not ok then
				table.insert(Mock.errors, err)
				print("  [signal error] " .. tostring(err))
			end
		end
	end
end

local deferred, timers = {}, {}

-- Threads are real coroutines so task.wait can yield, like the engine's scheduler.
local function resume(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then
		local trace = debug.traceback(co, tostring(err))
		table.insert(Mock.errors, trace)
		print("  [thread error] " .. trace)
	end
end

local function runThread(fn, ...)
	resume(coroutine.create(fn), ...)
end

task = {
	spawn = function(fn, ...) runThread(fn, ...) end,
	defer = function(fn, ...) table.insert(deferred, { fn = fn, args = table.pack(...) }) end,
	delay = function(t, fn, ...) table.insert(timers, { at = Mock.clock + (t or 0), fn = fn, args = table.pack(...) }) end,
	wait = function(t)
		local co, main = coroutine.running()
		if main then
			error("task.wait called on the main test thread; wrap the code in task.spawn", 2)
		end
		local started = Mock.clock
		table.insert(timers, { at = Mock.clock + (t or 0), co = co })
		coroutine.yield()
		return Mock.clock - started
	end,
}

function Mock.flush()
	local guard = 0
	while #deferred > 0 do
		guard = guard + 1
		assert(guard < 1000, "deferred queue never drained")
		local list = deferred
		deferred = {}
		for _, d in ipairs(list) do runThread(d.fn, table.unpack(d.args, 1, d.args.n)) end
	end
end

os.clock = function() return Mock.clock end
tick = os.clock

--------------------------------------------------------------------------------
-- Datatypes
--------------------------------------------------------------------------------

local function datatype(name, fields)
	local mt = { __typeof = name }
	mt.__index = function(self, k)
		local getter = mt.getters and mt.getters[k]
		if getter then return getter(self) end
		local method = mt.methods and mt.methods[k]
		if method then return method end
		error(tostring(k) .. " is not a valid member of " .. name, 2)
	end
	mt.__newindex = function() error(name .. " is immutable", 2) end
	return mt
end

local function num(v, what)
	if type(v) ~= "number" then error((what or "value") .. " must be a number, got " .. type(v), 3) end
	return v
end

-- UDim
local UDimMT = datatype("UDim")
UDimMT.__eq = function(a, b) return rawget(a, "Scale") == rawget(b, "Scale") and rawget(a, "Offset") == rawget(b, "Offset") end
UDim = { new = function(s, o) return setmetatable({ Scale = num(s or 0, "UDim scale"), Offset = num(o or 0, "UDim offset") }, UDimMT) end }

-- UDim2
local UDim2MT = datatype("UDim2")
UDim2MT.__eq = function(a, b) return rawget(a, "X") == rawget(b, "X") and rawget(a, "Y") == rawget(b, "Y") end
UDim2MT.__add = function(a, b) return UDim2.new(a.X.Scale + b.X.Scale, a.X.Offset + b.X.Offset, a.Y.Scale + b.Y.Scale, a.Y.Offset + b.Y.Offset) end
UDim2MT.getters = { Width = function(s) return rawget(s, "X") end, Height = function(s) return rawget(s, "Y") end }
UDim2 = {
	new = function(xs, xo, ys, yo)
		return setmetatable({ X = UDim.new(xs or 0, xo or 0), Y = UDim.new(ys or 0, yo or 0) }, UDim2MT)
	end,
	fromOffset = function(x, y) return UDim2.new(0, x or 0, 0, y or 0) end,
	fromScale = function(x, y) return UDim2.new(x or 0, 0, y or 0, 0) end,
}

-- Vector2
local Vector2MT = datatype("Vector2")
Vector2MT.__eq = function(a, b) return rawget(a, "X") == rawget(b, "X") and rawget(a, "Y") == rawget(b, "Y") end
Vector2MT.__add = function(a, b) return Vector2.new(a.X + b.X, a.Y + b.Y) end
Vector2MT.__sub = function(a, b) return Vector2.new(a.X - b.X, a.Y - b.Y) end
Vector2MT.__mul = function(a, b)
	if type(b) == "number" then return Vector2.new(a.X * b, a.Y * b) end
	return Vector2.new(a.X * b.X, a.Y * b.Y)
end
Vector2MT.__tostring = function(v) return rawget(v, "X") .. ", " .. rawget(v, "Y") end
Vector2MT.getters = { Magnitude = function(v) return math.sqrt(v.X ^ 2 + v.Y ^ 2) end }
Vector2 = { new = function(x, y) return setmetatable({ X = num(x or 0, "Vector2.X"), Y = num(y or 0, "Vector2.Y") }, Vector2MT) end }
Vector2.zero = Vector2.new(0, 0)

-- Color3
local Color3MT = datatype("Color3")
Color3MT.__eq = function(a, b)
	return math.abs(rawget(a, "R") - rawget(b, "R")) < 1e-9 and math.abs(rawget(a, "G") - rawget(b, "G")) < 1e-9 and math.abs(rawget(a, "B") - rawget(b, "B")) < 1e-9
end
Color3MT.__tostring = function(c) return string.format("%.3f, %.3f, %.3f", rawget(c, "R"), rawget(c, "G"), rawget(c, "B")) end
Color3MT.methods = {
	Lerp = function(a, b, t)
		assert(typeof(b) == "Color3", "Lerp expects Color3")
		return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
	end,
	ToHSV = function(c) return Color3.toHSV(c) end,
	ToHex = function(c)
		local function h(x) return string.format("%02X", math.floor(math.max(0, math.min(1, x)) * 255 + 0.5)) end
		return h(c.R) .. h(c.G) .. h(c.B)
	end,
}
Color3 = {
	new = function(r, g, b) return setmetatable({ R = num(r or 0, "R"), G = num(g or 0, "G"), B = num(b or 0, "B") }, Color3MT) end,
	fromRGB = function(r, g, b) return Color3.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255) end,
	fromHSV = function(h, s, v)
		num(h, "hue") num(s, "sat") num(v, "val")
		local i = math.floor(h * 6)
		local f = h * 6 - i
		local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
		i = i % 6
		if i == 0 then return Color3.new(v, t, p) elseif i == 1 then return Color3.new(q, v, p)
		elseif i == 2 then return Color3.new(p, v, t) elseif i == 3 then return Color3.new(p, q, v)
		elseif i == 4 then return Color3.new(t, p, v) else return Color3.new(v, p, q) end
	end,
	toHSV = function(c)
		local r, g, b = c.R, c.G, c.B
		local max, min = math.max(r, g, b), math.min(r, g, b)
		local h, s, v = 0, 0, max
		local d = max - min
		if max > 0 then s = d / max end
		if d > 0 then
			if max == r then h = (g - b) / d % 6 elseif max == g then h = (b - r) / d + 2 else h = (r - g) / d + 4 end
			h = h / 6
		end
		return h, s, v
	end,
	fromHex = function(hex)
		if type(hex) ~= "string" then error("Unable to convert hex", 2) end
		hex = hex:gsub("^#", "")
		if not hex:match("^%x%x%x%x%x%x$") then error("Unable to convert characters to hex value", 2) end
		return Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
	end,
}

-- Sequences
local CSKMT = datatype("ColorSequenceKeypoint")
ColorSequenceKeypoint = { new = function(t, c)
	assert(typeof(c) == "Color3", "ColorSequenceKeypoint expects Color3")
	return setmetatable({ Time = num(t), Value = c }, CSKMT)
end }
local CSMT = datatype("ColorSequence")
ColorSequence = { new = function(a, b)
	local points
	if typeof(a) == "Color3" then
		points = { ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(1, b or a) }
	else
		points = a
		assert(type(points) == "table" and #points >= 2, "ColorSequence needs at least 2 keypoints")
		assert(points[1].Time == 0 and points[#points].Time == 1, "ColorSequence must start at 0 and end at 1")
		for i = 2, #points do assert(points[i].Time >= points[i - 1].Time, "ColorSequence keypoints must be ordered") end
	end
	return setmetatable({ Keypoints = points }, CSMT)
end }
local NSKMT = datatype("NumberSequenceKeypoint")
NumberSequenceKeypoint = { new = function(t, v) return setmetatable({ Time = num(t), Value = num(v) }, NSKMT) end }
local NSMT = datatype("NumberSequence")
NumberSequence = { new = function(a, b)
	if type(a) == "number" then
		return setmetatable({ Keypoints = { NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b or a) } }, NSMT)
	end
	return setmetatable({ Keypoints = a }, NSMT)
end }

-- TweenInfo / Font
local TweenInfoMT = datatype("TweenInfo")
local FontMT = datatype("Font")

--------------------------------------------------------------------------------
-- Enums
--------------------------------------------------------------------------------

local enumNames = {
	KeyCode = { "Unknown", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
		"Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Escape", "Backspace", "Delete", "Return", "Space", "Tab",
		"LeftShift", "RightShift", "LeftControl", "RightControl", "LeftAlt", "RightAlt", "Insert", "Home", "End", "PageUp", "PageDown",
		"F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "CapsLock", "LeftSuper", "RightSuper" },
	UserInputType = { "MouseButton1", "MouseButton2", "MouseButton3", "MouseWheel", "MouseMovement", "Touch", "Keyboard", "Focus", "None" },
	UserInputState = { "Begin", "Change", "End", "Cancel", "None" },
	TextXAlignment = { "Left", "Right", "Center" },
	TextYAlignment = { "Top", "Center", "Bottom" },
	AutomaticSize = { "None", "X", "Y", "XY" },
	FillDirection = { "Horizontal", "Vertical" },
	SortOrder = { "LayoutOrder", "Name" },
	HorizontalAlignment = { "Left", "Center", "Right" },
	VerticalAlignment = { "Top", "Center", "Bottom" },
	EasingStyle = { "Linear", "Sine", "Back", "Quad", "Quart", "Quint", "Bounce", "Elastic", "Exponential", "Circular", "Cubic" },
	EasingDirection = { "In", "Out", "InOut" },
	ScrollingDirection = { "X", "Y", "XY" },
	ScrollBarInset = { "None", "ScrollBar", "Always" },
	TextTruncate = { "None", "AtEnd", "SplitWord" },
	ZIndexBehavior = { "Global", "Sibling" },
	ScreenInsets = { "None", "DeviceSafeInsets", "CoreUISafeInsets", "TopbarSafeInsets" },
	Font = { "Code", "Gotham", "GothamBold", "SourceSans", "RobotoMono", "BuilderSans" },
	FontWeight = { "Regular", "Bold" },
	ThumbnailType = { "HeadShot", "AvatarBust", "AvatarThumbnail" },
	ThumbnailSize = { "Size48x48", "Size60x60", "Size100x100", "Size150x150" },
	ApplyStrokeMode = { "Contextual", "Border" },
}

local EnumItemMT = { __typeof = "EnumItem" }
EnumItemMT.__index = function(_, k) error(tostring(k) .. " is not a valid member of EnumItem", 2) end
EnumItemMT.__tostring = function(item) return "Enum." .. rawget(item, "__enum") .. "." .. rawget(item, "Name") end

local EnumTypeMT = { __typeof = "Enum" }
EnumTypeMT.__index = function(self, k)
	error(tostring(k) .. " is not a valid member of \"Enum." .. rawget(self, "__name") .. "\"", 2)
end
EnumTypeMT.__tostring = function(self) return rawget(self, "__name") end

Enum = {}
for enumName, names in pairs(enumNames) do
	local enumType = setmetatable({ __name = enumName }, EnumTypeMT)
	for i, itemName in ipairs(names) do
		rawset(enumType, itemName, setmetatable({ Name = itemName, Value = i - 1, EnumType = enumType, __enum = enumName }, EnumItemMT))
	end
	Enum[enumName] = enumType
end
setmetatable(Enum, { __index = function(_, k) error(tostring(k) .. " is not a valid EnumItem type", 2) end })

TweenInfo = { new = function(time, style, direction)
	assert(style == nil or (typeof(style) == "EnumItem" and style.EnumType == Enum.EasingStyle), "bad EasingStyle")
	assert(direction == nil or (typeof(direction) == "EnumItem" and direction.EnumType == Enum.EasingDirection), "bad EasingDirection")
	return setmetatable({ Time = time or 1 }, TweenInfoMT)
end }

Font = {
	fromEnum = function(e)
		assert(typeof(e) == "EnumItem" and e.EnumType == Enum.Font, "Font.fromEnum expects Enum.Font")
		return setmetatable({ Family = "rbxasset://fonts/families/" .. e.Name .. ".json" }, FontMT)
	end,
	new = function(family) return setmetatable({ Family = family }, FontMT) end,
}

--------------------------------------------------------------------------------
-- Instances
--------------------------------------------------------------------------------

local P = {}
local function props(list)
	local out = {}
	for name, spec in pairs(list) do out[name] = spec end
	return out
end
local function merge(...)
	local out = {}
	for _, t in ipairs({ ... }) do for k, v in pairs(t) do out[k] = v end end
	return out
end

local function E(name) return { enum = name } end

P.Instance = { Name = "string", Parent = "Instance?", Archivable = "boolean" }
P.GuiBase = merge(P.Instance, {
	Size = "UDim2", Position = "UDim2", AnchorPoint = "Vector2", BackgroundColor3 = "Color3", BackgroundTransparency = "number",
	BorderSizePixel = "number", BorderColor3 = "Color3", Visible = "boolean", ZIndex = "number", LayoutOrder = "number",
	ClipsDescendants = "boolean", AutomaticSize = E("AutomaticSize"), Active = "boolean", Rotation = "number",
	Selectable = "boolean", Interactable = "boolean",
	AbsolutePosition = "readonly", AbsoluteSize = "readonly",
})
P.Text = {
	Text = "string", TextColor3 = "Color3", TextSize = "number", Font = E("Font"), FontFace = "Font",
	TextXAlignment = E("TextXAlignment"), TextYAlignment = E("TextYAlignment"), TextWrapped = "boolean",
	TextTruncate = E("TextTruncate"), TextTransparency = "number", RichText = "boolean", TextScaled = "boolean",
	TextBounds = "readonly", LineHeight = "number", TextStrokeTransparency = "number",
}
P.Button = { AutoButtonColor = "boolean", Modal = "boolean", Selected = "boolean" }
P.Image = { Image = "string", ImageColor3 = "Color3", ImageTransparency = "number" }

local Classes = {
	Frame = { props = P.GuiBase, gui = true },
	TextLabel = { props = merge(P.GuiBase, P.Text), gui = true },
	TextButton = { props = merge(P.GuiBase, P.Text, P.Button), gui = true, button = true },
	TextBox = { props = merge(P.GuiBase, P.Text, { PlaceholderText = "string", PlaceholderColor3 = "Color3", ClearTextOnFocus = "boolean", MultiLine = "boolean", TextEditable = "boolean" }), gui = true, textbox = true },
	ImageLabel = { props = merge(P.GuiBase, P.Image), gui = true },
	ImageButton = { props = merge(P.GuiBase, P.Image, P.Button), gui = true, button = true },
	ScrollingFrame = { props = merge(P.GuiBase, {
		CanvasSize = "UDim2", AutomaticCanvasSize = E("AutomaticSize"), ScrollBarThickness = "number", ScrollBarImageColor3 = "Color3",
		ScrollingDirection = E("ScrollingDirection"), CanvasPosition = "Vector2", VerticalScrollBarInset = E("ScrollBarInset"),
		ScrollingEnabled = "boolean", AbsoluteCanvasSize = "readonly", AbsoluteWindowSize = "readonly", ScrollBarImageTransparency = "number",
	}), gui = true },
	ScreenGui = { props = merge(P.Instance, { ResetOnSpawn = "boolean", ZIndexBehavior = E("ZIndexBehavior"), IgnoreGuiInset = "boolean", DisplayOrder = "number", Enabled = "boolean", ScreenInsets = E("ScreenInsets"), AbsoluteSize = "readonly", AbsolutePosition = "readonly" }), layer = true },
	UIListLayout = { props = merge(P.Instance, { SortOrder = E("SortOrder"), Padding = "UDim", FillDirection = E("FillDirection"), HorizontalAlignment = E("HorizontalAlignment"), VerticalAlignment = E("VerticalAlignment"), Wraps = "boolean", AbsoluteContentSize = "readonly" }) },
	UIPadding = { props = merge(P.Instance, { PaddingTop = "UDim", PaddingRight = "UDim", PaddingBottom = "UDim", PaddingLeft = "UDim" }) },
	UIGradient = { props = merge(P.Instance, { Color = "ColorSequence", Transparency = "NumberSequence", Rotation = "number", Offset = "Vector2", Enabled = "boolean" }) },
	UIStroke = { props = merge(P.Instance, { Color = "Color3", Thickness = "number", Transparency = "number", ApplyStrokeMode = E("ApplyStrokeMode"), Enabled = "boolean" }) },
	UISizeConstraint = { props = merge(P.Instance, { MinSize = "Vector2", MaxSize = "Vector2" }) },
	UICorner = { props = merge(P.Instance, { CornerRadius = "UDim" }) },
	UIScale = { props = merge(P.Instance, { Scale = "number" }) },
	NumberValue = { props = merge(P.Instance, { Value = "number" }) },
	Folder = { props = P.Instance },
}

local Defaults = {
	Size = function() return UDim2.new() end, Position = function() return UDim2.new() end, AnchorPoint = function() return Vector2.new() end,
	BackgroundColor3 = function() return Color3.new(1, 1, 1) end, BackgroundTransparency = 0, BorderSizePixel = 1, Visible = true,
	ZIndex = 1, LayoutOrder = 0, ClipsDescendants = false, Active = false, Rotation = 0, Text = function(i) return i.ClassName == "TextBox" and "TextBox" or "Label" end,
	TextColor3 = function() return Color3.new(0, 0, 0) end, TextSize = 14, TextTransparency = 0, Image = "", ImageColor3 = function() return Color3.new(1, 1, 1) end,
	CanvasPosition = function() return Vector2.new() end, Value = 0, Enabled = true, PlaceholderText = "", Offset = function() return Vector2.new() end,
	AutomaticSize = function() return Enum.AutomaticSize.None end, Interactable = true, RichText = false, TextWrapped = false,
	TextXAlignment = function() return Enum.TextXAlignment.Center end, TextYAlignment = function() return Enum.TextYAlignment.Center end,
	PlaceholderColor3 = function() return Color3.fromRGB(178, 178, 178) end,
}

local Instance_ = {}
local InstanceMT = { __typeof = "Instance" }
local Events = {
	common = { "Changed", "ChildAdded", "ChildRemoved", "Destroying", "AncestryChanged" },
	gui = { "InputBegan", "InputChanged", "InputEnded", "MouseEnter", "MouseLeave", "MouseMoved" },
	button = { "Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up" },
	textbox = { "Focused", "FocusLost" },
}

local function isEvent(class, key)
	for _, e in ipairs(Events.common) do if e == key then return true end end
	if class.gui then for _, e in ipairs(Events.gui) do if e == key then return true end end end
	if class.button then for _, e in ipairs(Events.button) do if e == key then return true end end end
	if class.textbox then for _, e in ipairs(Events.textbox) do if e == key then return true end end end
	return false
end

local VIEW = Vector2.new(1280, 720)
Mock.screenGuis = {}

-- Simulates a resize / device rotation: every ScreenGui reports the new AbsoluteSize.
-- the layout engine has no caching; freeze it while reading a finished scene (renderer)
function Mock.freezeLayout(on)
	Mock.layoutCache = on and { size = {}, pos = {} } or nil
end

function Mock.setViewport(size)
	VIEW = size
	for _, gui in ipairs(Mock.screenGuis) do
		local signal = rawget(gui, "__propSignals").AbsoluteSize
		if signal then signal:Fire() end
	end
end

-- A small layout engine: UDim2 sizing, UIPadding, vertical/horizontal UIListLayout stacking and AutomaticSize.
local function isRoot(inst)
	return inst.__class.layer or rawget(inst, "__className") == "Folder"
end

local function childOfClass(inst, className)
	for _, c in ipairs(rawget(inst, "__children")) do
		if rawget(c, "__className") == className then return c end
	end
end

local function pad(inst)
	local p = childOfClass(inst, "UIPadding")
	if not p then return 0, 0, 0, 0 end
	local t = rawget(p, "__props")
	local function o(u) return u and u.Offset or 0 end
	return o(t.PaddingTop), o(t.PaddingRight), o(t.PaddingBottom), o(t.PaddingLeft)
end

local function guiKids(inst)
	local out = {}
	for i, c in ipairs(rawget(inst, "__children")) do
		if c.__class.gui and c.__props.Visible ~= false then table.insert(out, { c = c, i = i }) end
	end
	table.sort(out, function(a, b)
		local la, lb = a.c.__props.LayoutOrder or 0, b.c.__props.LayoutOrder or 0
		if la == lb then return a.i < b.i end
		return la < lb
	end)
	local list = {}
	for i, e in ipairs(out) do list[i] = e.c end
	return list
end

local function autoOn(inst, axis)
	local a = inst.__props.AutomaticSize
	if not a then return false end
	return a.Name == "XY" or a.Name == axis
end

local intrinsic

local absSize
local function extent(c, axis)
	local s = c.__props.Size or UDim2.new()
	local base = axis == "X" and s.X.Offset or s.Y.Offset
	-- like Roblox: a scale-sized child of an auto-sizing box is measured against the
	-- box's own container, so a full-width line stretches the box to fill that
	local scale = axis == "X" and s.X.Scale or s.Y.Scale
	if scale > 0 then
		local box = rawget(c, "__parent")
		local function contentSized(inst)
			local size = inst.__props.Size or UDim2.new()
			return inst.__class.gui and autoOn(inst, axis) and (axis == "X" and size.X.Scale or size.Y.Scale) == 0
		end
		-- climb past every box that sizes purely from content; the first real
		-- container is what Roblox measures the scale against
		local outer = box and contentSized(box) and rawget(box, "__parent") or nil
		while outer and contentSized(outer) do
			outer = rawget(outer, "__parent")
		end
		if outer then
			local size = absSize(outer)
			base = base + scale * (axis == "X" and size.X or size.Y)
		end
	end
	if autoOn(c, axis) then return math.max(base, intrinsic(c, axis)) end
	return base
end

-- Monospace metrics (the Code font is ~0.5em wide). wrapWidth enables word wrap.
local function measure(text, size, wrapWidth)
	text = text or ""
	local charWidth = size * 0.5
	local widest, lines = 0, 0
	for line in (text .. "\n"):gmatch("(.-)\n") do
		local width = #line * charWidth
		if wrapWidth and wrapWidth > 0 and width > wrapWidth then
			local count, current = 1, 0
			for word in line:gmatch("%S+") do
				local w = (#word + (current > 0 and 1 or 0)) * charWidth
				if current > 0 and current + w > wrapWidth then
					count = count + 1
					current = #word * charWidth
				else
					current = current + w
				end
			end
			lines = lines + count
			widest = math.max(widest, wrapWidth)
		else
			lines = lines + 1
			widest = math.max(widest, width)
		end
	end
	return Vector2.new(widest, lines * size)
end
Mock.measure = measure

local absWidth

function intrinsic(inst, axis)
	local t, r, b, l = pad(inst)
	local padding = axis == "X" and (l + r) or (t + b)
	local class = inst.__class
	if class.props.TextBounds then
		local props = inst.__props
		local wrapWidth
		if axis == "Y" and props.TextWrapped and not autoOn(inst, "X") then
			wrapWidth = absWidth(inst) - l - r
		end
		local text = props.Text
		if (text == nil or text == "") and inst.__className == "TextBox" then text = props.PlaceholderText end
		local bounds = measure(text, props.TextSize or 14, wrapWidth)
		local value = axis == "X" and bounds.X or bounds.Y
		local kids = 0
		for _, c in ipairs(guiKids(inst)) do kids = math.max(kids, extent(c, axis)) end
		return math.max(value, kids) + padding
	end
	local layout = childOfClass(inst, "UIListLayout")
	local total = 0
	if layout and layout.__props.Wraps and axis == "Y" and layout.__props.FillDirection and layout.__props.FillDirection.Name == "Horizontal" then
		local gap = layout.__props.Padding and layout.__props.Padding.Offset or 0
		local width = absWidth(inst) - l - r
		local cursor, lineHeight = 0, 0
		for _, c in ipairs(guiKids(inst)) do
			local w = absWidth(c)
			if cursor > 0 and cursor + w > width + 0.5 then
				total = total + lineHeight + gap
				cursor, lineHeight = 0, 0
			end
			cursor = cursor + w + gap
			lineHeight = math.max(lineHeight, extent(c, "Y"))
		end
		return total + lineHeight + padding
	end
	if layout then
		local lp = layout.__props
		local horizontal = lp.FillDirection and lp.FillDirection.Name == "Horizontal"
		local gap = lp.Padding and lp.Padding.Offset or 0
		local along = (horizontal and axis == "X") or (not horizontal and axis == "Y")
		local kids = guiKids(inst)
		for i, c in ipairs(kids) do
			local e = extent(c, axis)
			if along then total = total + e + (i > 1 and gap or 0) else total = math.max(total, e) end
		end
	else
		for _, c in ipairs(guiKids(inst)) do
			local p = c.__props.Position or UDim2.new()
			local off = axis == "X" and p.X.Offset or p.Y.Offset
			total = math.max(total, off + extent(c, axis))
		end
	end
	return total + padding
end

local function uiScale(inst)
	local scale = childOfClass(inst, "UIScale")
	return scale and (scale.__props.Scale or 1) or 1
end

-- width only depends on ancestors' widths, so wrapping can use it without recursing into heights
function absWidth(inst)
	if isRoot(inst) then return VIEW.X end
	local parent = rawget(inst, "__parent")
	local pw = VIEW.X
	if parent then
		local _, r, _, l = pad(parent)
		pw = (isRoot(parent) and VIEW.X or absWidth(parent)) - l - r
	end
	local s = inst.__props.Size or UDim2.new()
	local w = pw * s.X.Scale + s.X.Offset
	if autoOn(inst, "X") then w = math.max(w, intrinsic(inst, "X")) end
	return w * uiScale(inst)
end

local absSizeRaw
function absSize(inst)
	local cache = Mock.layoutCache
	if cache then
		local hit = cache.size[inst]
		if not hit then hit = absSizeRaw(inst) cache.size[inst] = hit end
		return hit
	end
	return absSizeRaw(inst)
end
function absSizeRaw(inst)
	if isRoot(inst) then return VIEW end
	local parent = rawget(inst, "__parent")
	local ps = VIEW
	if parent then
		local t, r, b, l = pad(parent)
		local raw = isRoot(parent) and VIEW or absSize(parent)
		ps = Vector2.new(raw.X - l - r, raw.Y - t - b)
	end
	local s = inst.__props.Size or UDim2.new()
	local w, h = ps.X * s.X.Scale + s.X.Offset, ps.Y * s.Y.Scale + s.Y.Offset
	if autoOn(inst, "X") then w = math.max(w, intrinsic(inst, "X")) end
	if autoOn(inst, "Y") then h = math.max(h, intrinsic(inst, "Y")) end
	local k = uiScale(inst)
	return Vector2.new(w * k, h * k)
end

local absPosRaw
local function absPos(inst)
	local cache = Mock.layoutCache
	if cache then
		local hit = cache.pos[inst]
		if not hit then hit = absPosRaw(inst) cache.pos[inst] = hit end
		return hit
	end
	return absPosRaw(inst)
end
function absPosRaw(inst)
	-- like the engine: AbsolutePosition is measured from below the 36px top bar,
	-- so a ScreenGui that ignores the inset starts at y = -36
	if isRoot(inst) then
		if rawget(inst, "__className") == "ScreenGui" and rawget(inst, "__props").IgnoreGuiInset then
			return Vector2.new(0, -36)
		end
		return Vector2.new()
	end
	local parent = rawget(inst, "__parent")
	if not parent then return Vector2.new() end
	local pp = absPos(parent)
	if rawget(parent, "__className") == "ScrollingFrame" then
		local scroll = rawget(parent, "__props").CanvasPosition
		if scroll then pp = Vector2.new(pp.X - scroll.X, pp.Y - scroll.Y) end
	end
	local t, r, b, l = pad(parent)
	local origin = Vector2.new(pp.X + l, pp.Y + t)
	local layout = childOfClass(parent, "UIListLayout")
	if layout and inst.__class.gui then
		local lp = layout.__props
		local horizontal = lp.FillDirection and lp.FillDirection.Name == "Horizontal"
		local gap = lp.Padding and lp.Padding.Offset or 0
		local raw = isRoot(parent) and VIEW or absSize(parent)
		local content = Vector2.new(raw.X - l - r, raw.Y - t - b)
		if horizontal and lp.Wraps then
			local cursor, lineY, lineHeight = 0, 0, 0
			for _, sib in ipairs(guiKids(parent)) do
				local size = absSize(sib)
				if cursor > 0 and cursor + size.X > content.X + 0.5 then
					lineY = lineY + lineHeight + gap
					cursor, lineHeight = 0, 0
				end
				if sib == inst then
					return Vector2.new(origin.X + cursor, origin.Y + lineY)
				end
				cursor = cursor + size.X + gap
				lineHeight = math.max(lineHeight, size.Y)
			end
		end
		local cum, before, total = 0, 0, 0
		local kids = guiKids(parent)
		for i, sib in ipairs(kids) do
			if sib == inst then before = cum end
			local size = absSize(sib)
			cum = cum + (horizontal and size.X or size.Y) + (i < #kids and gap or 0)
		end
		total = cum
		local mine = absSize(inst)
		local h = lp.HorizontalAlignment and lp.HorizontalAlignment.Name or "Left"
		local v = lp.VerticalAlignment and lp.VerticalAlignment.Name or "Top"
		local function along(name, space)
			if name == "Center" then return (space - total) / 2 end
			if name == "Right" or name == "Bottom" then return space - total end
			return 0
		end
		local function cross(name, space, size)
			if name == "Center" then return (space - size) / 2 end
			if name == "Right" or name == "Bottom" then return space - size end
			return 0
		end
		if horizontal then
			return Vector2.new(origin.X + along(h, content.X) + before, origin.Y + cross(v, content.Y, mine.Y))
		end
		return Vector2.new(origin.X + cross(h, content.X, mine.X), origin.Y + along(v, content.Y) + before)
	end
	local raw = isRoot(parent) and VIEW or absSize(parent)
	local ps = Vector2.new(raw.X - l - r, raw.Y - t - b)
	local p = inst.__props.Position or UDim2.new()
	local a = inst.__props.AnchorPoint or Vector2.new()
	local size = absSize(inst)
	return Vector2.new(origin.X + ps.X * p.X.Scale + p.X.Offset - a.X * size.X, origin.Y + ps.Y * p.Y.Scale + p.Y.Offset - a.Y * size.Y)
end

local function checkValue(inst, key, spec, value)
	if spec == "readonly" then error(key .. " is read-only on " .. inst.ClassName, 3) end
	if type(spec) == "table" then
		if not (typeof(value) == "EnumItem" and rawget(value, "__enum") == spec.enum) then
			error("Unable to assign property " .. key .. ". EnumItem of type " .. spec.enum .. " expected, got " .. tostring(value), 3)
		end
		return
	end
	if spec == "Instance?" then
		if value ~= nil and typeof(value) ~= "Instance" then error("Parent must be an Instance", 3) end
		return
	end
	local actual = typeof(value)
	if actual ~= spec then
		error("Unable to assign property " .. key .. " on " .. inst.ClassName .. ". " .. spec .. " expected, got " .. actual, 3)
	end
	if spec == "number" and value ~= value then error("NaN assigned to " .. key, 3) end
end

InstanceMT.__index = function(self, key)
	local method = Instance_[key]
	if method then return method end
	local class = rawget(self, "__class")
	if key == "ClassName" then return rawget(self, "__className") end
	if key == "Parent" then return rawget(self, "__parent") end
	if isEvent(class, key) then
		local events = rawget(self, "__events")
		events[key] = events[key] or Signal.new()
		return events[key]
	end
	local spec = class.props[key]
	if not spec then error(tostring(key) .. " is not a valid member of " .. rawget(self, "__className"), 2) end
	if key == "AbsoluteSize" then return absSize(self) end
	if key == "AbsolutePosition" then return absPos(self) end
	if key == "TextBounds" then
		local wrap = self.TextWrapped and absWidth(self) or nil
		return measure(self.Text, self.TextSize, wrap)
	end
	if key == "AbsoluteContentSize" or key == "AbsoluteCanvasSize" then return Vector2.new(0, 0) end
	if key == "AbsoluteWindowSize" then return absSize(self) end
	local value = rawget(self, "__props")[key]
	if value == nil then
		local default = Defaults[key]
		if type(default) == "function" then default = default(self) end
		return default
	end
	return value
end

InstanceMT.__newindex = function(self, key, value)
	local class = rawget(self, "__class")
	if key == "Parent" then
		if rawget(self, "__destroyed") then error("The Parent property of " .. tostring(self.Name) .. " is locked", 2) end
		checkValue(self, key, "Instance?", value)
		local old = rawget(self, "__parent")
		if old == value then return end
		if old then
			local kids = rawget(old, "__children")
			for i, c in ipairs(kids) do if c == self then table.remove(kids, i) break end end
		end
		rawset(self, "__parent", value)
		if value then table.insert(rawget(value, "__children"), self) end
		return
	end
	local spec = class.props[key]
	if not spec then error(tostring(key) .. " is not a valid member of " .. rawget(self, "__className"), 2) end
	checkValue(self, key, spec, value)
	local store = rawget(self, "__props")
	local old = store[key]
	store[key] = value
	if old ~= value then
		local signals = rawget(self, "__propSignals")
		if signals[key] then signals[key]:Fire() end
		if key == "Text" and signals.TextBounds then signals.TextBounds:Fire() end
		local events = rawget(self, "__events")
		if events.Changed then
			if self.ClassName == "NumberValue" then
				if key == "Value" then events.Changed:Fire(value) end
			else
				events.Changed:Fire(key)
			end
		end
	end
end

InstanceMT.__tostring = function(self) return tostring(rawget(self, "__props").Name or rawget(self, "__className")) end

Mock.instances = 0

Instance = {
	new = function(className, parent)
		local class = Classes[className]
		if not class then error("Unable to create an Instance of type \"" .. tostring(className) .. "\"", 2) end
		Mock.instances = Mock.instances + 1
		local inst = setmetatable({
			__class = class, __className = className, __props = { Name = className },
			__children = {}, __events = {}, __propSignals = {},
		}, InstanceMT)
		if parent then inst.Parent = parent end
		if className == "ScreenGui" then table.insert(Mock.screenGuis, inst) end
		return inst
	end,
}

function Instance_.Destroy(self)
	if rawget(self, "__destroyed") then return end
	for _, child in ipairs({ table.unpack(rawget(self, "__children")) }) do child:Destroy() end
	local events = rawget(self, "__events")
	if events.Destroying then events.Destroying:Fire() end
	self.Parent = nil
	rawset(self, "__destroyed", true)
	for _, s in pairs(events) do s.handlers = {} end
	for _, s in pairs(rawget(self, "__propSignals")) do s.handlers = {} end
end
function Instance_.GetChildren(self) return { table.unpack(rawget(self, "__children")) } end
function Instance_.GetDescendants(self)
	local out = {}
	local function walk(i) for _, c in ipairs(rawget(i, "__children")) do table.insert(out, c) walk(c) end end
	walk(self)
	return out
end
function Instance_.FindFirstChild(self, name)
	for _, c in ipairs(rawget(self, "__children")) do if c.Name == name then return c end end
	return nil
end
function Instance_.FindFirstChildOfClass(self, className)
	for _, c in ipairs(rawget(self, "__children")) do if c.ClassName == className then return c end end
	return nil
end
function Instance_.WaitForChild(self, name)
	return self:FindFirstChild(name) or error("infinite yield on " .. name)
end
function Instance_.IsA(self, className)
	local cn = rawget(self, "__className")
	if cn == className then return true end
	local class = rawget(self, "__class")
	if className == "GuiObject" then return class.gui == true end
	if className == "GuiButton" then return class.button == true end
	if className == "Instance" then return true end
	return false
end
function Instance_.GetPropertyChangedSignal(self, prop)
	local class = rawget(self, "__class")
	if not class.props[prop] then error(prop .. " is not a valid property name.", 2) end
	local signals = rawget(self, "__propSignals")
	signals[prop] = signals[prop] or Signal.new()
	return signals[prop]
end
function Instance_.IsFocused(self) return Mock.focused == self end
function Instance_.CaptureFocus(self) Mock.focus(self) end
function Instance_.ReleaseFocus(self) if Mock.focused == self then Mock.unfocus(false) end end
function Instance_.IsDescendantOf(self, ancestor)
	local p = rawget(self, "__parent")
	while p do if p == ancestor then return true end p = rawget(p, "__parent") end
	return false
end

--------------------------------------------------------------------------------
-- Services
--------------------------------------------------------------------------------

local function service(name, t)
	t.Name = name
	t.ClassName = name
	return t
end

Mock.mouse = Vector2.new(0, 0)

local UIS = service("UserInputService", {
	InputBegan = Signal.new(), InputChanged = Signal.new(), InputEnded = Signal.new(),
	TouchEnabled = false, KeyboardEnabled = true, MouseEnabled = true,
})
function UIS:GetMouseLocation() return Mock.mouse + Vector2.new(0, 36) end
function UIS:GetFocusedTextBox() return Mock.focused end

local TweenService = service("TweenService", {})
function TweenService:Create(inst, info, goals)
	assert(typeof(inst) == "Instance", "TweenService:Create expects an Instance")
	assert(typeof(info) == "TweenInfo", "TweenService:Create expects TweenInfo")
	for k, v in pairs(goals) do
		local spec = rawget(inst, "__class").props[k]
		if not spec then error("TweenService: " .. k .. " is not a property of " .. inst.ClassName, 2) end
		checkValue(inst, k, spec, v)
	end
	local tween = { Completed = Signal.new() }
	function tween:Play()
		for k, v in pairs(goals) do
			if not rawget(inst, "__destroyed") then inst[k] = v end
		end
		task.defer(function() tween.Completed:Fire() end)
	end
	function tween:Cancel() end
	return tween
end

local RunService = service("RunService", { RenderStepped = Signal.new(), Heartbeat = Signal.new(), Stepped = Signal.new() })
function RunService:IsStudio() return false end

-- Minimal JSON
local function encode(v, out)
	local t = type(v)
	if t == "nil" then out[#out + 1] = "null"
	elseif t == "boolean" then out[#out + 1] = tostring(v)
	elseif t == "number" then
		if v == math.floor(v) and math.abs(v) < 1e15 then out[#out + 1] = string.format("%d", v) else out[#out + 1] = string.format("%.17g", v) end
	elseif t == "string" then out[#out + 1] = string.format("%q", v):gsub("\\\n", "\\n")
	elseif t == "table" then
		if #v > 0 or next(v) == nil then
			if next(v) == nil then out[#out + 1] = "[]" return end
			out[#out + 1] = "["
			for i, x in ipairs(v) do if i > 1 then out[#out + 1] = "," end encode(x, out) end
			out[#out + 1] = "]"
		else
			out[#out + 1] = "{"
			local first = true
			for k, x in pairs(v) do
				if type(k) ~= "string" then error("JSONEncode: non-string key") end
				if not first then out[#out + 1] = "," end
				first = false
				encode(k, out) out[#out + 1] = ":" encode(x, out)
			end
			out[#out + 1] = "}"
		end
	else error("JSONEncode: cannot encode " .. typeof(v)) end
end

local function decode(s)
	local i = 1
	local function ws() i = s:find("[^%s]", i) or #s + 1 end
	local value
	local function str()
		local j = i + 1
		local buf = {}
		while true do
			local c = s:sub(j, j)
			if c == "\"" then break end
			if c == "\\" then
				local n = s:sub(j + 1, j + 1)
				buf[#buf + 1] = ({ n = "\n", t = "\t", r = "\r" })[n] or n
				j = j + 2
			else buf[#buf + 1] = c j = j + 1 end
		end
		i = j + 1
		return table.concat(buf)
	end
	function value()
		ws()
		local c = s:sub(i, i)
		if c == "{" then
			i = i + 1 local t = {} ws()
			if s:sub(i, i) == "}" then i = i + 1 return t end
			while true do
				ws() local k = str() ws() assert(s:sub(i, i) == ":") i = i + 1
				t[k] = value() ws()
				local d = s:sub(i, i) i = i + 1
				if d == "}" then return t end
			end
		elseif c == "[" then
			i = i + 1 local t = {} ws()
			if s:sub(i, i) == "]" then i = i + 1 return t end
			while true do
				t[#t + 1] = value() ws()
				local d = s:sub(i, i) i = i + 1
				if d == "]" then return t end
			end
		elseif c == "\"" then return str()
		elseif s:sub(i, i + 3) == "true" then i = i + 4 return true
		elseif s:sub(i, i + 4) == "false" then i = i + 5 return false
		elseif s:sub(i, i + 3) == "null" then i = i + 4 return nil
		else
			local n = s:match("^-?[%d%.eE+-]+", i)
			i = i + #n
			return tonumber(n)
		end
	end
	return value()
end

local HttpService = service("HttpService", {})
function HttpService:JSONEncode(v) local out = {} encode(v, out) return table.concat(out) end
function HttpService:JSONDecode(s) return decode(s) end

local GuiService = service("GuiService", {})
function GuiService:GetGuiInset() return Vector2.new(0, 36), Vector2.new(0, 0) end

local CoreGui = Instance.new("Folder")
CoreGui.Name = "CoreGui"
local PlayerGui = Instance.new("Folder")
PlayerGui.Name = "PlayerGui"

local Players = service("Players", {
	LocalPlayer = {
		Name = "Tester", DisplayName = "Tester", UserId = 1, LocaleId = "en-us",
		WaitForChild = function(_, name) assert(name == "PlayerGui") return PlayerGui end,
	},
})
function Players:GetUserThumbnailAsync(id, kind, size)
	assert(type(id) == "number", "user id must be a number")
	assert(rawget(kind, "__enum") == "ThumbnailType" and rawget(size, "__enum") == "ThumbnailSize")
	return "rbxthumb://type=AvatarHeadShot&id=" .. id .. "&w=48&h=48"
end

local TextService = service("TextService", {})

Mock.ping = 48.4
Mock.region = "us"
local Stats = service("Stats", {
	Network = { ServerStatsItem = { ["Data Ping"] = { GetValue = function() return Mock.ping end } } },
})

local services = {
	UserInputService = UIS, TweenService = TweenService, RunService = RunService, HttpService = HttpService,
	GuiService = GuiService, CoreGui = CoreGui, Players = Players, TextService = TextService, Stats = Stats, LocalizationService = service("LocalizationService", {
		GetCountryRegionForPlayerAsync = function(_, player) assert(player, "player required") return Mock.region end,
	}),
}

game = {
	GetService = function(_, name) return services[name] or error("no service " .. name) end,
	HttpGet = function() error("HttpGet unavailable in mock") end,
}
workspace = { CurrentCamera = { ViewportSize = VIEW } }

Mock.CoreGui = CoreGui
Mock.UIS = UIS
Mock.RunService = RunService

--------------------------------------------------------------------------------
-- Executor file API
--------------------------------------------------------------------------------

Mock.files, Mock.folders = {}, {}
function writefile(path, data)
	local folder = path:match("^(.*)/[^/]+$")
	if folder and not Mock.folders[folder] then error("folder does not exist: " .. folder) end
	Mock.files[path] = data
end
function readfile(path) return Mock.files[path] or error("file not found: " .. path) end
function isfile(path) return Mock.files[path] ~= nil end
function isfolder(path) return Mock.folders[path] == true end
function makefolder(path) Mock.folders[path] = true end
function delfile(path) Mock.files[path] = nil end
function listfiles(folder)
	local out = {}
	for path in pairs(Mock.files) do
		local dir, name = path:match("^(.*)/([^/]+)$")
		if dir == folder then table.insert(out, folder .. "\\" .. name) end
	end
	return out
end
function setclipboard(text) Mock.clipboard = text end
function identifyexecutor() return "MockExec", "1.0" end

--------------------------------------------------------------------------------
-- Input simulation helpers
--------------------------------------------------------------------------------

local function input(kind, keyCode, position)
	return setmetatable({
		UserInputType = Enum.UserInputType[kind],
		KeyCode = keyCode or Enum.KeyCode.Unknown,
		Position = position or Vector2.new(Mock.mouse.X, Mock.mouse.Y),
		UserInputState = Enum.UserInputState.Begin,
	}, { __typeof = "InputObject" })
end

function Mock.center(gui)
	local p, s = gui.AbsolutePosition, gui.AbsoluteSize
	return Vector2.new(p.X + s.X / 2, p.Y + s.Y / 2)
end

function Mock.click(gui, at)
	Mock.mouse = at or Mock.center(gui)
	local down = input("MouseButton1")
	UIS.InputBegan:Fire(down, false)
	gui.InputBegan:Fire(down)
	UIS.InputEnded:Fire(down, false)
	gui.InputEnded:Fire(down)
	if gui:IsA("GuiButton") then
		gui.MouseButton1Click:Fire()
		gui.Activated:Fire(down, 1)
	end
	Mock.flush()
end

function Mock.clickAt(point)
	Mock.mouse = point
	local down = input("MouseButton1")
	UIS.InputBegan:Fire(down, false)
	UIS.InputEnded:Fire(down, false)
	Mock.flush()
end

function Mock.drag(gui, from, to, steps)
	Mock.mouse = from
	local down = input("MouseButton1")
	UIS.InputBegan:Fire(down, false)
	gui.InputBegan:Fire(down)
	steps = steps or 4
	for i = 1, steps do
		local t = i / steps
		Mock.mouse = Vector2.new(from.X + (to.X - from.X) * t, from.Y + (to.Y - from.Y) * t)
		UIS.InputChanged:Fire(input("MouseMovement"), false)
	end
	UIS.InputEnded:Fire(input("MouseButton1"), false)
	Mock.flush()
end

function Mock.keyDown(name)
	local key = Enum.KeyCode[name]
	UIS.InputBegan:Fire(input("Keyboard", key), false)
	Mock.flush()
end

function Mock.keyUp(name)
	local key = Enum.KeyCode[name]
	UIS.InputEnded:Fire(input("Keyboard", key), false)
	Mock.flush()
end

function Mock.press(name)
	Mock.keyDown(name)
	Mock.keyUp(name)
end

function Mock.mouseDown(kind)
	UIS.InputBegan:Fire(input(kind), false)
	Mock.flush()
end

function Mock.mouseUp(kind)
	UIS.InputEnded:Fire(input(kind), false)
	Mock.flush()
end

function Mock.focus(box)
	Mock.focused = box
	box.Focused:Fire()
end

function Mock.unfocus(enter)
	local box = Mock.focused
	Mock.focused = nil
	if box then box.FocusLost:Fire(enter, nil) end
	Mock.flush()
end

function Mock.typeInto(box, text, enter)
	Mock.focus(box)
	box.Text = text
	Mock.unfocus(enter ~= false)
end

-- Touch: each finger is one persistent InputObject (as in Roblox). Positions are in
-- AbsolutePosition space, which already excludes the 36px top inset, like the engine.
function Mock.finger(at)
	local obj = input("Touch", nil, Vector2.new(at.X, at.Y))
	return obj
end

function Mock.touchBegin(finger, gui)
	UIS.InputBegan:Fire(finger, false)
	if gui then gui.InputBegan:Fire(finger) end
	Mock.flush()
end

function Mock.touchMove(finger, to)
	finger.Position = Vector2.new(to.X, to.Y)
	UIS.InputChanged:Fire(finger, false)
	Mock.flush()
end

function Mock.touchEnd(finger, gui, activate)
	UIS.InputEnded:Fire(finger, false)
	if gui then gui.InputEnded:Fire(finger) end
	if activate and gui and gui:IsA("GuiButton") then gui.Activated:Fire(finger, 1) end
	Mock.flush()
end

function Mock.tap(gui, at)
	local finger = Mock.finger(at or Mock.center(gui))
	Mock.touchBegin(finger, gui)
	Mock.touchEnd(finger, gui, true)
end

function Mock.touchDrag(gui, from, to, steps)
	local finger = Mock.finger(from)
	Mock.touchBegin(finger, gui)
	steps = steps or 4
	for i = 1, steps do
		local t = i / steps
		Mock.touchMove(finger, Vector2.new(from.X + (to.X - from.X) * t, from.Y + (to.Y - from.Y) * t))
	end
	Mock.touchEnd(finger, gui, false)
end

function Mock.hover(gui)
	gui.MouseEnter:Fire()
end

function Mock.advance(seconds, step)
	step = step or 1 / 60
	local target = Mock.clock + seconds
	while Mock.clock < target - 1e-9 do
		Mock.clock = Mock.clock + step
		RunService.RenderStepped:Fire(step)
		RunService.Heartbeat:Fire(step)
		local due = {}
		for i = #timers, 1, -1 do
			if timers[i].at <= Mock.clock then table.insert(due, 1, table.remove(timers, i)) end
		end
		for _, t in ipairs(due) do
			if t.co then
				resume(t.co)
			else
				runThread(t.fn, table.unpack(t.args, 1, t.args.n))
			end
		end
		Mock.flush()
	end
end

-- Descendant search helpers
function Mock.find(root, predicate)
	for _, d in ipairs(root:GetDescendants()) do
		if predicate(d) then return d end
	end
	return nil
end

function Mock.findAll(root, predicate)
	local out = {}
	for _, d in ipairs(root:GetDescendants()) do
		if predicate(d) then table.insert(out, d) end
	end
	return out
end

function Mock.byText(root, text)
	return Mock.find(root, function(d)
		local ok, value = pcall(function() return d.Text end)
		return ok and value == text
	end)
end

return Mock
