--[[
	Onyx UI
	cheat-menu style ui library for roblox

	local Onyx = loadstring(game:HttpGet("https://raw.githubusercontent.com/onyxuilibrary/onyx-ui/main/source.lua"))()
]]

local Onyx = {
	Version = "1.1.0",
	Windows = {},
}

--------------------------------------------------------------------------------
-- Services
--------------------------------------------------------------------------------

local cloneref = cloneref or function(object)
	return object
end

local function Service(name)
	return cloneref(game:GetService(name))
end

local Players = Service("Players")
local UserInputService = Service("UserInputService")
local TweenService = Service("TweenService")
local RunService = Service("RunService")
local HttpService = Service("HttpService")
local GuiService = Service("GuiService")
local CoreGui = Service("CoreGui")

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------------------------------------
-- Utilities
--------------------------------------------------------------------------------

local AUTO_X = Enum.AutomaticSize.X
local AUTO_Y = Enum.AutomaticSize.Y
local AUTO_XY = Enum.AutomaticSize.XY

local function LowerKeys(props)
	local out = {}
	if type(props) == "table" then
		for key, value in pairs(props) do
			if type(key) == "string" then
				out[string.lower(key)] = value
			else
				out[key] = value
			end
		end
	end
	return out
end

-- first non-nil value out of a list of option names (keys are lowercased)
local function Pick(p, default, ...)
	for i = 1, select("#", ...) do
		local value = p[select(i, ...)]
		if value ~= nil then
			return value
		end
	end
	return default
end

local function Create(className, props, children)
	local instance = Instance.new(className)
	local parent
	for key, value in pairs(props or {}) do
		if key == "Parent" then
			parent = value
		else
			instance[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

local function Padding(parent, top, right, bottom, left)
	return Create("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right or top),
		PaddingBottom = UDim.new(0, bottom or top),
		PaddingLeft = UDim.new(0, left or right or top),
		Parent = parent,
	})
end

local function List(parent, padding, direction, props)
	local layout = Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, padding or 0),
		FillDirection = direction or Enum.FillDirection.Vertical,
		Parent = parent,
	})
	for key, value in pairs(props or {}) do
		pcall(function()
			layout[key] = value
		end)
	end
	return layout
end

local function Tween(instance, goals, duration, style, direction)
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(duration or 0.15, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		goals
	)
	tween:Play()
	return tween
end

local function Call(callback, ...)
	if type(callback) ~= "function" then
		return
	end
	local ok, err = pcall(callback, ...)
	if not ok then
		warn("[Onyx] callback error: " .. tostring(err))
	end
end

local function Decimals(step)
	local text = tostring(step)
	local dot = string.find(text, ".", 1, true)
	if not dot or string.find(text, "e", 1, true) then
		return 0
	end
	local decimals = #text - dot
	if string.sub(text, dot + 1) == "0" then
		return 0
	end
	return decimals
end

local function FormatNumber(value)
	if value == math.floor(value) and math.abs(value) < 1e15 then
		if value == 0 then
			return "0"
		end
		return string.format("%.0f", value)
	end
	local text = string.format("%.3f", value)
	text = (string.gsub(text, "0+$", ""))
	text = (string.gsub(text, "%.$", ""))
	return text
end

local function Snap(value, min, max, step)
	if step and step > 0 then
		value = min + math.floor((value - min) / step + 0.5) * step
	end
	value = math.clamp(value, min, max)
	return tonumber(string.format("%." .. Decimals(step or 1) .. "f", value))
end

local function CopyList(list)
	local out = {}
	for i, value in ipairs(list or {}) do
		out[i] = value
	end
	return out
end

local function IndexOf(list, value)
	for i, item in ipairs(list) do
		if item == value then
			return i
		end
	end
	return nil
end

local function ToColor3(value, fallback)
	local kind = typeof(value)
	if kind == "Color3" then
		return value
	elseif kind == "ColorSequence" then
		return value.Keypoints[1].Value
	elseif kind == "string" then
		local ok, color = pcall(Color3.fromHex, value)
		if ok and color then
			return color
		end
	elseif kind == "table" and value[1] then
		return Color3.fromRGB(value[1], value[2] or 0, value[3] or 0)
	end
	return fallback
end

local function ContrastText(color)
	local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
	if luminance > 0.6 then
		return Color3.fromRGB(14, 14, 14)
	end
	return Color3.fromRGB(255, 255, 255)
end

local function IconImage(icon)
	if icon == nil or icon == 0 or icon == "" then
		return nil
	end
	if type(icon) == "number" then
		return "rbxassetid://" .. string.format("%.0f", icon)
	end
	if type(icon) == "string" then
		if string.match(icon, "^%d+$") then
			return "rbxassetid://" .. icon
		end
		if string.match(icon, "^rbx") or string.match(icon, "^https?://") then
			return icon
		end
	end
	return nil
end

local function PointerPosition(input)
	if input and input.UserInputType == Enum.UserInputType.Touch then
		local inset = GuiService:GetGuiInset()
		return Vector2.new(input.Position.X, input.Position.Y) + inset
	end
	return UserInputService:GetMouseLocation()
end

local function IsTouchDevice()
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

local function IsPointerDown(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function Inside(guiObject, point)
	if not guiObject or not guiObject.Parent then
		return false
	end
	local position, size = guiObject.AbsolutePosition, guiObject.AbsoluteSize
	return point.X >= position.X and point.X <= position.X + size.X and point.Y >= position.Y and point.Y <= position.Y + size.Y
end

local function SetClipboard(text)
	local setter = setclipboard or toclipboard or (Clipboard and Clipboard.set)
	if type(setter) ~= "function" then
		return false
	end
	return (pcall(setter, text))
end

--------------------------------------------------------------------------------
-- Key names
--------------------------------------------------------------------------------

local ShortKeyNames = {
	LeftShift = "LSHIFT",
	RightShift = "RSHIFT",
	LeftControl = "LCTRL",
	RightControl = "RCTRL",
	LeftAlt = "LALT",
	RightAlt = "RALT",
	LeftSuper = "LWIN",
	RightSuper = "RWIN",
	Return = "ENTER",
	Backspace = "BACK",
	CapsLock = "CAPS",
	PageUp = "PGUP",
	PageDown = "PGDN",
	Insert = "INS",
	Delete = "DEL",
	MouseButton1 = "MB1",
	MouseButton2 = "MB2",
	MouseButton3 = "MB3",
	One = "1", Two = "2", Three = "3", Four = "4", Five = "5",
	Six = "6", Seven = "7", Eight = "8", Nine = "9", Zero = "0",
}

local MouseAliases = { MB1 = "MouseButton1", MB2 = "MouseButton2", MB3 = "MouseButton3" }

local function ParseKey(value)
	if value == nil or value == "" or value == "None" or value == "NONE" then
		return nil
	end
	if typeof(value) == "EnumItem" then
		if value == Enum.KeyCode.Unknown then
			return nil
		end
		return value
	end
	if type(value) == "string" then
		local enumType, name = string.match(value, "^Enum%.(%w+)%.(%w+)$")
		if not enumType then
			enumType, name = string.match(value, "^(%w+)%.(%w+)$")
		end
		name = name or value
		name = MouseAliases[string.upper(name)] or name
		if enumType ~= "UserInputType" then
			local ok, key = pcall(function()
				return Enum.KeyCode[name]
			end)
			if ok and key then
				return key
			end
			ok, key = pcall(function()
				return Enum.KeyCode[string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)]
			end)
			if ok and key then
				return key
			end
		end
		local ok, inputType = pcall(function()
			return Enum.UserInputType[name]
		end)
		if ok and inputType then
			return inputType
		end
	end
	return nil
end

local function KeyName(key)
	if key == nil then
		return "NONE"
	end
	return ShortKeyNames[key.Name] or string.upper(key.Name)
end

local function KeyMatches(key, input)
	if key == nil then
		return false
	end
	if key.EnumType == Enum.KeyCode then
		return input.KeyCode == key
	end
	return input.UserInputType == key
end

--------------------------------------------------------------------------------
-- Themes
--------------------------------------------------------------------------------

local function RGB(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local BaseTheme = {
	Accent = RGB(150, 196, 60),
	Background = RGB(14, 14, 14),
	Header = RGB(18, 18, 18),
	Panel = RGB(21, 21, 21),
	Element = RGB(33, 33, 33),
	ElementHover = RGB(44, 44, 44),
	Border = RGB(42, 42, 42),
	BorderLight = RGB(58, 58, 58),
	Outline = RGB(0, 0, 0),
	Text = RGB(225, 225, 225),
	TextDim = RGB(140, 140, 140),
	Placeholder = RGB(86, 86, 86),
	Error = RGB(226, 72, 72),
	Success = RGB(112, 208, 92),
	Shadow = RGB(0, 0, 0),
	Font = Font.fromEnum(Enum.Font.Code),
	Rainbow = true,
	LiveAnimation = true,
}

local Themes = {
	default = {},
	cobalt = { Accent = RGB(76, 132, 255), Rainbow = false },
	ember = { Accent = RGB(255, 124, 50), Rainbow = false },
	amethyst = { Accent = RGB(164, 108, 255), Rainbow = false },
	frost = {
		Accent = RGB(104, 210, 255),
		Rainbow = false,
		Background = RGB(12, 14, 17),
		Header = RGB(15, 18, 22),
		Panel = RGB(18, 21, 26),
		Element = RGB(29, 34, 41),
		ElementHover = RGB(39, 45, 54),
		Border = RGB(37, 43, 51),
		BorderLight = RGB(52, 60, 71),
	},
	rose = { Accent = RGB(255, 94, 144), Rainbow = false },
}

local ThemeNames = { "default", "cobalt", "ember", "amethyst", "frost", "rose" }

-- alternate theme key names people tend to use
local ThemeAliases = {
	accentcolor = "Accent",
	accentstroke = "Accent",
	sliderprogress = "Accent",
	dropdownhighlight = "Accent",
	windowcolor = "Background",
	contentcolor = "Text",
	titlingcolor = "Text",
	elementtexthovercolor = "Text",
	actioncolor = "TextDim",
	tabcolor = "TextDim",
	elementstroke = "Border",
	surfacestroke = "Border",
	sliderstroke = "Border",
	elementstrokehover = "BorderLight",
	elementgradient = "Element",
	sliderbackground = "Element",
	toggletrack = "Element",
	fieldbackground = "Element",
	neutralbutton = "Element",
	sliderbackgroundhover = "ElementHover",
	neutralbuttonhover = "ElementHover",
	statbackground = "Panel",
	placeholdercolor = "Placeholder",
	errorcolor = "Error",
	shadowcolor = "Shadow",
	font = "Font",
	titlefont = "Font",
	liveanimation = "LiveAnimation",
}

local function ResolveThemeKey(key)
	if BaseTheme[key] ~= nil then
		return key
	end
	return ThemeAliases[string.lower(key)]
end

local function BuildTheme(spec, current)
	local theme = {}
	if type(spec) == "table" then
		for key, value in pairs(current or BaseTheme) do
			theme[key] = value
		end
		theme.Name = (current and current.Name) or "custom"
		local accentChanged, rainbowSet = false, false
		for key, value in pairs(spec) do
			local token = type(key) == "string" and ResolveThemeKey(key)
			if token then
				local expected = typeof(BaseTheme[token])
				if expected == "Color3" then
					value = ToColor3(value, theme[token])
				elseif token == "Font" and typeof(value) == "EnumItem" then
					value = Font.fromEnum(value)
				end
				if typeof(value) == expected then
					theme[token] = value
					accentChanged = accentChanged or token == "Accent"
					rainbowSet = rainbowSet or token == "Rainbow"
				end
			end
		end
		if accentChanged and not rainbowSet then
			theme.Rainbow = false
		end
		return theme
	end

	local name = type(spec) == "string" and string.lower(spec) or "default"
	local preset = Themes[name]
	if not preset then
		warn("[Onyx] unknown theme '" .. tostring(spec) .. "', using default")
		name, preset = "default", Themes.default
	end
	for key, value in pairs(BaseTheme) do
		theme[key] = value
	end
	for key, value in pairs(preset) do
		theme[key] = value
	end
	theme.Name = name
	return theme
end

local RainbowPalette = { RGB(55, 177, 218), RGB(201, 72, 205), RGB(204, 227, 53) }

local HueSequence = (function()
	local points = {}
	for i = 0, 6 do
		table.insert(points, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((i / 6) % 1, 1, 1)))
	end
	return ColorSequence.new(points)
end)()

local Shine = ColorSequence.new(Color3.new(1, 1, 1), RGB(196, 196, 196))

--------------------------------------------------------------------------------
-- Configuration files
--------------------------------------------------------------------------------

local FileSystem = {}

function FileSystem.Available()
	return type(writefile) == "function"
		and type(readfile) == "function"
		and type(isfile) == "function"
		and type(isfolder) == "function"
		and type(makefolder) == "function"
end

function FileSystem.EnsureFolder(path)
	local built = ""
	for part in string.gmatch(path, "[^/]+") do
		built = built == "" and part or (built .. "/" .. part)
		if not isfolder(built) then
			makefolder(built)
		end
	end
end

local function Serialize(value)
	local kind = typeof(value)
	if kind == "Color3" then
		return { __type = "Color3", hex = value:ToHex() }
	elseif kind == "EnumItem" then
		return { __type = "EnumItem", value = tostring(value) }
	end
	return value
end

local function Deserialize(value)
	if type(value) == "table" then
		if value.__type == "Color3" then
			return Color3.fromHex(value.hex)
		elseif value.__type == "EnumItem" then
			return ParseKey(value.value)
		end
	end
	return value
end

--------------------------------------------------------------------------------
-- Element base
--------------------------------------------------------------------------------

local GUTTER = 18

local Element = {}
Element.__index = Element

local function ElementClass()
	local class = {}
	class.__index = class
	setmetatable(class, { __index = Element })
	return class
end

function Element:_connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(self._connections, connection)
	return connection
end

function Element:_setDescription(text)
	local label = self._desc
	if not label then
		return
	end
	if text and text ~= "" then
		self.window:_text(label, text)
		label.Visible = true
	else
		label.Text = ""
		label.Visible = false
	end
end

function Element:_reserve(pixels)
	if self._label then
		self._label.Size = UDim2.new(1, -(self._inset + pixels), 1, 0)
	end
end

function Element:_slot(height, order)
	return self.window:_frame({
		Name = "Slot",
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		LayoutOrder = order or 3,
		Parent = self.stack,
	})
end

function Element:_changed()
	self.window:_valueChanged(self)
end

function Element:Lock(reason)
	self._locked = true
	if self._lockCover then
		self._lockCover.Visible = true
	end
	if self._desc then
		self:_setDescription(reason or "Locked")
		self.window:_paint(self._desc, { TextColor3 = "Placeholder" })
	end
end

function Element:Unlock()
	self._locked = false
	if self._lockCover then
		self._lockCover.Visible = false
	end
	if self._desc then
		self:_setDescription(self.description)
		self.window:_paint(self._desc, { TextColor3 = "TextDim" })
	end
end

function Element:IsLocked()
	return self._locked == true
end

function Element:MoveTo(index)
	local siblings = self.holder.children
	local current = IndexOf(siblings, self)
	if not current then
		return
	end
	table.remove(siblings, current)
	index = math.clamp(math.floor(index), 1, #siblings + 1)
	table.insert(siblings, index, self)
	for i, sibling in ipairs(siblings) do
		sibling.root.LayoutOrder = i
	end
end

function Element:MoveToTop()
	self:MoveTo(1)
end

function Element:MoveToBottom()
	self:MoveTo(#self.holder.children)
end

function Element:MoveUp()
	local index = IndexOf(self.holder.children, self)
	if index then
		self:MoveTo(index - 1)
	end
end

function Element:MoveDown()
	local index = IndexOf(self.holder.children, self)
	if index then
		self:MoveTo(index + 1)
	end
end

function Element:Remove()
	if self._removed then
		return
	end
	self._removed = true
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	if self._onRemove then
		self._onRemove()
	end
	local siblings = self.holder.children
	local index = IndexOf(siblings, self)
	if index then
		table.remove(siblings, index)
	end
	if self.flag and self.window._elements[self.flag] == self then
		self.window._elements[self.flag] = nil
	end
	if self.holder._childRemoved then
		self.holder:_childRemoved(self)
	end
	self.root:Destroy()
end

Element.Destroy = Element.Remove

-- root frame, label row, icon + description
local function NewElement(class, holder, p, kind, rowHeight, labelInset)
	local window = holder.window
	local self = setmetatable({
		window = window,
		holder = holder,
		kind = kind,
		name = Pick(p, nil, "name", "title"),
		description = Pick(p, nil, "description", "desc", "info"),
		_connections = {},
		_inset = labelInset or 0,
	}, class)

	local root = window:_frame({
		Name = kind,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = AUTO_Y,
		BackgroundTransparency = 1,
	})
	self.root = root

	-- separate stack so the lock cover can sit on top
	local stack = window:_frame({
		Name = "Stack",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = AUTO_Y,
		BackgroundTransparency = 1,
		Parent = root,
	})
	List(stack, 2)
	self.stack = stack

	-- indent so labels line up with toggle text
	if (labelInset or 0) == 0 and holder.kind ~= "row" and kind ~= "Divider" and kind ~= "SubHeader" then
		Padding(stack, 0, 0, 0, GUTTER)
	end

	if rowHeight and rowHeight > 0 then
		local row = window:_frame({
			Name = "Row",
			Size = UDim2.new(1, 0, 0, rowHeight),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Parent = stack,
		})
		self.row = row

		local inset = self._inset
		local image = IconImage(Pick(p, nil, "icon", "image"))
		if image then
			local icon = Create("ImageLabel", {
				Name = "Icon",
				Image = image,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(13, 13),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, inset, 0.5, 0),
				Parent = row,
			})
			window:_paint(icon, { ImageColor3 = "TextDim" })
			inset = inset + 18
			self._icon = icon
		end
		self._inset = inset

		self._label = window:_label({
			Name = "Label",
			Size = UDim2.new(1, -inset, 1, 0),
			Position = UDim2.fromOffset(inset, 0),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		}, "Text")
		window:_text(self._label, self.name or "")
	end

	self._desc = window:_label({
		Name = "Description",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = AUTO_Y,
		TextSize = 12,
		TextWrapped = true,
		LayoutOrder = 2,
		Visible = false,
		Parent = stack,
	}, "TextDim")
	Padding(self._desc, 0, 0, 1, labelInset or 0)
	self:_setDescription(self.description)

	self._lockCover = window:_frame({
		Name = "Lock",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.45,
		ZIndex = 8,
		Active = true,
		Visible = false,
		Parent = root,
	}, { BackgroundColor3 = "Panel" })

	return self
end

local function Mount(self, estimate)
	self.holder:_add(self, estimate or 20)
	return self
end

local function Register(self, p)
	local window = self.window
	local flag = Pick(p, nil, "flag")
	if flag == nil or flag == "" then
		local base = tostring(self.name or self.kind)
		flag = base
		local n = 2
		while window._elements[flag] do
			flag = base .. " (" .. n .. ")"
			n = n + 1
		end
	elseif window._elements[flag] then
		warn("[Onyx] duplicate flag '" .. tostring(flag) .. "', the newer element replaces the older one")
	end
	self.flag = flag
	self.forgetState = Pick(p, false, "forgetstate") == true
	window._elements[flag] = self

	local pending = window._pending[flag]
	if pending ~= nil and not self.forgetState then
		window._pending[flag] = nil
		task.defer(function()
			if not self._removed then
				window._loading = true
				self:_load(pending)
				window._loading = false
			end
		end)
	end
end

local function Hover(window, target, onEnter, onLeave, owner)
	local enter = target.MouseEnter:Connect(onEnter)
	local leave = target.MouseLeave:Connect(onLeave)
	if owner then
		table.insert(owner._connections, enter)
		table.insert(owner._connections, leave)
	end
end

--------------------------------------------------------------------------------
-- Elements
--------------------------------------------------------------------------------

local Elements = {}

-- Button ----------------------------------------------------------------------

local Button = ElementClass()

function Elements.Button(holder, p)
	local self = NewElement(Button, holder, p, "Button", 0)
	local window = self.window
	self.callback = Pick(p, nil, "callback")

	local outer, inner = window:_box(self:_slot(22, 1), UDim2.fromScale(1, 1), nil, "Element")
	self._fill = inner
	local label = window:_label({
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = inner,
	}, "Text")
	window:_text(label, self.name or "Button")
	self._label = label

	local image = IconImage(Pick(p, nil, "icon", "image"))
	if image then
		Create("ImageLabel", {
			Image = image,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(13, 13),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 6, 0.5, 0),
			Parent = inner,
		})
	end

	local hitbox = window:_hitbox(outer)
	Hover(window, hitbox, function()
		if not self._locked then
			window:_paint(outer, { BackgroundColor3 = "BorderLight" })
			window:_paint(inner, { BackgroundColor3 = "ElementHover" })
		end
	end, function()
		window:_paint(outer, { BackgroundColor3 = "Outline" })
		window:_paint(inner, { BackgroundColor3 = "Element" })
	end, self)

	self:_connect(hitbox.Activated, function()
		if self._locked then
			return
		end
		inner.BackgroundColor3 = window.Theme.Accent
		Tween(inner, { BackgroundColor3 = window.Theme.ElementHover }, 0.3)
		Call(self.callback)
	end)

	return Mount(self, 26)
end

function Button:Set(name)
	self.name = name
	self.window:_text(self._label, name)
end

function Button:Fire()
	Call(self.callback)
end

-- Toggle ----------------------------------------------------------------------

local Toggle = ElementClass()

function Elements.Toggle(holder, p)
	local self = NewElement(Toggle, holder, p, "Toggle", 18, GUTTER)
	local window = self.window
	self.callback = Pick(p, nil, "callback")
	self.value = Pick(p, false, "value", "currentvalue", "default") == true

	local outer, inner = window:_box(self.row, UDim2.fromOffset(10, 10), UDim2.new(0, 0, 0.5, -5), function(theme)
		return self.value and theme.Accent or theme.Element
	end)
	self._outer, self._fill = outer, inner

	local hitbox = window:_hitbox(self.row, 3)
	Hover(window, hitbox, function()
		if not self._locked then
			window:_paint(self._label, { TextColor3 = "Text" })
			window:_paint(outer, { BackgroundColor3 = "BorderLight" })
		end
	end, function()
		self:_paintLabel()
		window:_paint(outer, { BackgroundColor3 = "Outline" })
	end, self)

	self:_connect(hitbox.Activated, function()
		if not self._locked then
			self:Set(not self.value)
		end
	end)

	self:_paintLabel()
	Register(self, p)
	return Mount(self, 20)
end

function Toggle:_paintLabel()
	self.window:_paint(self._label, { TextColor3 = self.value and "Text" or "TextDim" })
end

function Toggle:Set(value, skipCallback)
	value = value == true
	local changed = value ~= self.value
	self.value = value
	self.CurrentValue = value
	self.window:_paint(self._fill, {
		BackgroundColor3 = function(theme)
			return self.value and theme.Accent or theme.Element
		end,
	}, true)
	self:_paintLabel()
	if not skipCallback then
		Call(self.callback, value)
	end
	if changed then
		self:_changed()
	end
end

function Toggle:_save()
	return self.value
end

function Toggle:_load(value)
	self:Set(value == true)
end

-- Slider ----------------------------------------------------------------------

local Slider = ElementClass()

function Elements.Slider(holder, p)
	local minimal = Pick(p, false, "minimal") == true
	local self = NewElement(Slider, holder, p, "Slider", minimal and 0 or 15)
	local window = self.window
	local range = Pick(p, nil, "range") or { 0, 100 }
	self.min = tonumber(range[1]) or 0
	self.max = tonumber(range[2]) or 100
	if self.max < self.min then
		self.min, self.max = self.max, self.min
	end
	self.increment = tonumber(Pick(p, 1, "increment", "step")) or 1
	self.suffix = Pick(p, "", "suffix")
	self.callback = Pick(p, nil, "callback")
	self.value = self:_clamp(tonumber(Pick(p, nil, "value", "currentvalue", "default")) or self.min)

	if not minimal then
		self._valueLabel = window:_label({
			Name = "Value",
			Size = UDim2.new(0, 80, 1, 0),
			Position = UDim2.new(1, -80, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextSize = 12,
			Parent = self.row,
		}, "TextDim")
		self:_reserve(84)
	end

	local slot = self:_slot(10, 3)
	local outer, inner = window:_box(slot, UDim2.new(1, 0, 0, 10), nil, "Element")
	inner.ClipsDescendants = true
	self._bar = outer
	self._fill = window:_frame({
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		Parent = inner,
	}, { BackgroundColor3 = "Accent" })
	Create("UIGradient", { Rotation = 90, Color = Shine, Parent = self._fill })

	local hitbox = window:_hitbox(outer, 6)
	Hover(window, hitbox, function()
		if not self._locked then
			window:_paint(outer, { BackgroundColor3 = "BorderLight" })
		end
	end, function()
		window:_paint(outer, { BackgroundColor3 = "Outline" })
	end, self)

	window:_draggable(self, hitbox, function(position)
		local size = outer.AbsoluteSize.X
		local alpha = size > 0 and math.clamp((position.X - outer.AbsolutePosition.X) / size, 0, 1) or 0
		local value = alpha >= 1 and self.max or self:_clamp(self.min + (self.max - self.min) * alpha)
		self._dragging = true
		if value ~= self.value then
			self:_apply(value)
			Call(self.callback, value, true)
		end
	end, function()
		self._dragging = false
		Call(self.callback, self.value, false)
		self:_changed()
	end)

	self:_render(false)
	Register(self, p)
	return Mount(self, minimal and 14 or 32)
end

function Slider:_clamp(value)
	if value >= self.max then
		return self.max
	end
	return Snap(value, self.min, self.max, self.increment)
end

function Slider:_render(animate)
	local span = self.max - self.min
	local alpha = span > 0 and (self.value - self.min) / span or 0
	local goal = UDim2.fromScale(alpha, 1)
	if animate then
		Tween(self._fill, { Size = goal }, 0.08)
	else
		self._fill.Size = goal
	end
	if self._valueLabel then
		self._valueLabel.Text = FormatNumber(self.value) .. tostring(self.suffix or "")
	end
end

function Slider:_apply(value)
	self.value = value
	self.CurrentValue = value
	self:_render(true)
end

function Slider:Set(value, skipCallback)
	value = self:_clamp(tonumber(value) or self.min)
	local changed = value ~= self.value
	self:_apply(value)
	if not skipCallback then
		Call(self.callback, value, false)
	end
	if changed then
		self:_changed()
	end
end

function Slider:SetRange(min, max)
	self.min, self.max = math.min(min, max), math.max(min, max)
	self:Set(self.value, true)
end

function Slider:_save()
	return self.value
end

function Slider:_load(value)
	if type(value) == "number" then
		self:Set(value)
	end
end

-- Dropdown --------------------------------------------------------------------

local Dropdown = ElementClass()

function Elements.Dropdown(holder, p)
	local hasName = Pick(p, nil, "name", "title") ~= nil
	local self = NewElement(Dropdown, holder, p, "Dropdown", hasName and 15 or 0)
	local window = self.window
	self.options = {}
	for _, option in ipairs(Pick(p, {}, "options") or {}) do
		table.insert(self.options, tostring(option))
	end
	self.multi = Pick(p, false, "multiselect", "multipleoptions", "multi") == true
	self.placeholder = Pick(p, nil, "placeholder")
	self.callback = Pick(p, nil, "callback")
	self.value = self:_normalize(Pick(p, nil, "value", "currentoption", "default"))
	self.CurrentOption = self.value

	local slot = self:_slot(20, 3)
	local outer, inner = window:_box(slot, UDim2.fromScale(1, 1), nil, "Element")
	self._box = outer
	self._display = window:_label({
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.fromOffset(6, 0),
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = inner,
	}, "Text")
	self._arrow = window:_label({
		Text = "+",
		Size = UDim2.new(0, 16, 1, 0),
		Position = UDim2.new(1, -18, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = inner,
	}, "TextDim")

	local hitbox = window:_hitbox(outer)
	Hover(window, hitbox, function()
		if not self._locked then
			window:_paint(outer, { BackgroundColor3 = "BorderLight" })
		end
	end, function()
		window:_paint(outer, { BackgroundColor3 = "Outline" })
	end, self)
	self:_connect(hitbox.Activated, function()
		if self._locked then
			return
		end
		if self._open then
			window:_closePopover()
		else
			self:_openList()
		end
	end)

	self._onRemove = function()
		if self._open then
			window:_closePopover()
		end
	end

	self:_renderDisplay()
	Register(self, p)
	return Mount(self, hasName and 40 or 24)
end

function Dropdown:_normalize(value)
	local list = {}
	if type(value) == "table" then
		for _, item in ipairs(value) do
			table.insert(list, tostring(item))
		end
	elseif value ~= nil then
		table.insert(list, tostring(value))
	end
	local out = {}
	for _, item in ipairs(list) do
		if IndexOf(self.options, item) and not IndexOf(out, item) then
			table.insert(out, item)
		end
	end
	if not self.multi and #out > 1 then
		out = { out[1] }
	end
	return out
end

function Dropdown:_renderDisplay()
	local window = self.window
	if #self.value == 0 then
		self._display.Text = window:_t(self.placeholder or "None")
		window:_paint(self._display, { TextColor3 = "Placeholder" })
	else
		self._display.Text = table.concat(self.value, ", ")
		window:_paint(self._display, { TextColor3 = "Text" })
	end
	self._arrow.Text = self._open and "-" or "+"
	if self._open and self._renderList then
		self._renderList()
	end
end

function Dropdown:_emit(skipCallback)
	self.CurrentOption = self.value
	self:_renderDisplay()
	if not skipCallback then
		if self.multi then
			Call(self.callback, CopyList(self.value))
		else
			Call(self.callback, self.value[1])
		end
	end
	self:_changed()
end

function Dropdown:_openList()
	local window = self.window
	local theme = window.Theme
	local rowHeight, maxRows = window._mobile and 26 or 18, 8
	local searchable = #self.options > maxRows

	local outer, fill = window:_rim({
		Name = "DropdownList",
		Size = UDim2.fromOffset(self._box.AbsoluteSize.X / window._scale, 0),
		ZIndex = 2,
	}, "Panel")

	local search
	if searchable then
		local boxOuter, boxInner = window:_box(fill, UDim2.new(1, 0, 0, 20), nil, "Element")
		boxOuter.LayoutOrder = 1
		search = window:_textbox({
			Size = UDim2.new(1, -12, 1, 0),
			Position = UDim2.fromOffset(6, 0),
			PlaceholderText = window:_t("Search..."),
			Text = "",
			TextSize = 12,
			Parent = boxInner,
		})
	end
	List(fill, 2)
	Padding(fill, 2)

	local scroller = Create("ScrollingFrame", {
		Name = "Options",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, rowHeight),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = AUTO_Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = theme.Accent,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		LayoutOrder = 2,
		Parent = fill,
	})
	List(scroller, 0)

	local function render()
		for _, child in ipairs(scroller:GetChildren()) do
			if child:IsA("GuiButton") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		local query = search and string.lower(search.Text) or ""
		local shown = 0
		for index, option in ipairs(self.options) do
			if query == "" or string.find(string.lower(option), query, 1, true) then
				shown = shown + 1
				local selected = IndexOf(self.value, option) ~= nil
				local button = Create("TextButton", {
					Name = option,
					Text = "",
					AutoButtonColor = false,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, rowHeight),
					LayoutOrder = index,
					Parent = scroller,
				})
				window:_paint(button, { BackgroundColor3 = "ElementHover" })
				local label = window:_label({
					Text = option,
					Size = UDim2.new(1, -12, 1, 0),
					Position = UDim2.fromOffset(6, 0),
					TextSize = 12,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = button,
				}, selected and "Accent" or "TextDim")
				button.MouseEnter:Connect(function()
					button.BackgroundTransparency = 0
					if not selected then
						window:_paint(label, { TextColor3 = "Text" })
					end
				end)
				button.MouseLeave:Connect(function()
					button.BackgroundTransparency = 1
					window:_paint(label, { TextColor3 = selected and "Accent" or "TextDim" })
				end)
				button.Activated:Connect(function()
					self:_choose(option)
				end)
			end
		end
		if shown == 0 then
			window:_label({
				Text = window:_t("No results"),
				Size = UDim2.new(1, -12, 0, rowHeight),
				Position = UDim2.fromOffset(6, 0),
				TextSize = 12,
				Parent = scroller,
			}, "Placeholder")
			shown = 1
		end
		scroller.Size = UDim2.new(1, 0, 0, math.min(shown, maxRows) * rowHeight)
	end

	self._renderList = render
	render()
	if search then
		search:GetPropertyChangedSignal("Text"):Connect(render)
	end

	self._open = true
	self._arrow.Text = "-"
	window:_openPopover(outer, self._box, function()
		self._open = false
		self._renderList = nil
		self._arrow.Text = "+"
	end)
end

function Dropdown:_choose(option)
	if self._locked then
		return
	end
	if self.multi then
		local index = IndexOf(self.value, option)
		if index then
			table.remove(self.value, index)
		else
			table.insert(self.value, option)
			local ordered = {}
			for _, item in ipairs(self.options) do
				if IndexOf(self.value, item) then
					table.insert(ordered, item)
				end
			end
			self.value = ordered
		end
		self:_emit(false)
	else
		self.value = { option }
		self.window:_closePopover()
		self:_emit(false)
	end
end

function Dropdown:Set(value, skipCallback)
	self.value = self:_normalize(value)
	self:_emit(skipCallback)
end

function Dropdown:Refresh(options, keepSelection)
	self.options = {}
	for _, option in ipairs(options or {}) do
		table.insert(self.options, tostring(option))
	end
	local before = table.concat(self.value, "\0")
	self.value = self:_normalize(self.value)
	local changed = table.concat(self.value, "\0") ~= before
	self.CurrentOption = self.value
	self:_renderDisplay()
	if changed and keepSelection ~= false then
		self:_emit(false)
	end
end

function Dropdown:Add(option)
	option = tostring(option)
	if not IndexOf(self.options, option) then
		table.insert(self.options, option)
		self:_renderDisplay()
	end
end

function Dropdown:Remove(option)
	if option == nil then
		return Element.Remove(self)
	end
	option = tostring(option)
	local index = IndexOf(self.options, option)
	if not index then
		return
	end
	table.remove(self.options, index)
	local selected = IndexOf(self.value, option)
	if selected then
		table.remove(self.value, selected)
		self:_emit(false)
	else
		self:_renderDisplay()
	end
end

function Dropdown:_save()
	return CopyList(self.value)
end

function Dropdown:_load(value)
	self:Set(value)
end

-- Input -----------------------------------------------------------------------

local Input = ElementClass()

function Elements.Input(holder, p)
	local hasName = Pick(p, nil, "name", "title") ~= nil
	local self = NewElement(Input, holder, p, "Input", hasName and 15 or 0)
	local window = self.window
	self.numeric = Pick(p, false, "numeric", "numbersonly") == true
	self.clearOnFocus = Pick(p, false, "clearonfocus") == true
	self.clearAfter = Pick(p, false, "removetextafterfocuslost") == true
	self.callback = Pick(p, nil, "callback")
	self.value = tostring(Pick(p, "", "value", "currentvalue", "default", "text"))

	local slot = self:_slot(20, 3)
	local outer, inner = window:_box(slot, UDim2.fromScale(1, 1), nil, "Element")
	self._outer = outer
	local box = window:_textbox({
		Size = UDim2.new(1, -12, 1, 0),
		Position = UDim2.fromOffset(6, 0),
		Text = self.value,
		TextSize = 12,
		Parent = inner,
	})
	window:_text(box, Pick(p, "", "placeholder", "placeholdertext"), "PlaceholderText")
	self._box = box

	self:_connect(box.Focused, function()
		if self._locked then
			box:ReleaseFocus()
			return
		end
		window:_paint(outer, { BackgroundColor3 = "Accent" })
		if self.clearOnFocus then
			box.Text = ""
		end
	end)

	self:_connect(box.FocusLost, function()
		window:_paint(outer, { BackgroundColor3 = "Outline" })
		if self._locked then
			box.Text = self.value
			return
		end
		local text = box.Text
		if self.numeric and tonumber(text) == nil then
			box.Text = self.value
			outer.BackgroundColor3 = window.Theme.Error
			Tween(outer, { BackgroundColor3 = window.Theme.Outline }, 0.6)
			return
		end
		self:Set(text)
		if self.clearAfter then
			box.Text = ""
		end
	end)

	Register(self, p)
	return Mount(self, hasName and 40 or 24)
end

function Input:Set(value, skipCallback)
	value = tostring(value == nil and "" or value)
	local changed = value ~= self.value
	self.value = value
	self.CurrentValue = value
	self._box.Text = value
	if not skipCallback then
		Call(self.callback, value)
	end
	if changed then
		self:_changed()
	end
end

function Input:_save()
	return self.value
end

function Input:_load(value)
	if value ~= nil then
		self:Set(value)
	end
end

-- Keybind ---------------------------------------------------------------------

local Keybind = ElementClass()

function Elements.Keybind(holder, p)
	local self = NewElement(Keybind, holder, p, "Keybind", 18)
	local window = self.window
	self.hold = Pick(p, false, "hold", "holdtointeract") == true
	self.holdThreshold = tonumber(Pick(p, 0.2, "holdthreshold")) or 0.2
	self.callback = Pick(p, nil, "callback")
	self.onChanged = Pick(p, nil, "onchanged", "changedcallback")
	self._isMenuKey = Pick(p, false, "_menukey") == true
	self.value = ParseKey(Pick(p, nil, "value", "currentkeybind", "default", "key"))
	if not self._isMenuKey and self.value and self.value == window.toggleKey then
		warn("[Onyx] keybind '" .. tostring(self.name) .. "' cannot use the menu key")
		self.value = nil
	end
	self.CurrentKeybind = self.value and self.value.Name or "None"

	local button = Create("TextButton", {
		Name = "Bind",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		AutomaticSize = AUTO_X,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0, 1),
		Parent = self.row,
	})
	window:_paint(button, { TextColor3 = "TextDim", FontFace = "Font" })
	button.TextSize = 12
	self._button = button
	self:_reserve(72)
	self:_renderKey()

	Hover(window, button, function()
		if not self._listening then
			window:_paint(button, { TextColor3 = "Text" })
		end
	end, function()
		if not self._listening then
			window:_paint(button, { TextColor3 = "TextDim" })
		end
	end, self)

	self:_connect(button.Activated, function()
		if self._locked or self._listening then
			return
		end
		self._listening = true
		window._listening = self
		button.Text = "[...]"
		window:_paint(button, { TextColor3 = "Accent" })
	end)

	self:_connect(UserInputService.InputBegan, function(input)
		if self._listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Escape then
					self:_stopListening()
				elseif input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
					self:_stopListening()
					self:Set(nil)
				else
					self:_stopListening()
					self:Set(input.KeyCode)
				end
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
				self:_stopListening()
				self:Set(input.UserInputType)
			elseif IsPointerDown(input) and not Inside(button, PointerPosition(input)) then
				self:_stopListening()
			end
			return
		end
		if self._locked or self._isMenuKey or not KeyMatches(self.value, input) then
			return
		end
		if UserInputService:GetFocusedTextBox() or window._listening then
			return
		end
		if self.hold then
			local token = {}
			self._holdToken = token
			task.delay(self.holdThreshold, function()
				if self._holdToken == token then
					self._held = true
					self.Holding = true
					Call(self.callback, true)
				end
			end)
		else
			Call(self.callback, self.value)
		end
	end)

	self:_connect(UserInputService.InputEnded, function(input)
		if not self.hold or not KeyMatches(self.value, input) then
			return
		end
		self._holdToken = nil
		if self._held then
			self._held = false
			self.Holding = false
			Call(self.callback, false)
		end
	end)

	self._onRemove = function()
		if window._listening == self then
			window._listening = nil
		end
	end

	Register(self, p)
	return Mount(self, 20)
end

function Keybind:_renderKey()
	self._button.Text = "[" .. KeyName(self.value) .. "]"
end

function Keybind:_stopListening()
	self._listening = false
	task.defer(function()
		if self.window._listening == self then
			self.window._listening = nil
		end
	end)
	self.window:_paint(self._button, { TextColor3 = "TextDim" })
	self:_renderKey()
end

function Keybind:Set(value, skipChanged)
	local key = ParseKey(value)
	if key and not self._isMenuKey and key == self.window.toggleKey then
		warn("[Onyx] " .. KeyName(key) .. " is the menu key and cannot be bound")
		self.window:Toast({ title = "Key in use", subtitle = KeyName(key) .. " toggles the menu", duration = 3 })
		self:_renderKey()
		return
	end
	local changed = key ~= self.value
	self.value = key
	self.CurrentKeybind = key and key.Name or "None"
	self._held = false
	self._holdToken = nil
	self:_renderKey()
	if not skipChanged then
		Call(self.onChanged, key)
	end
	if changed then
		self:_changed()
	end
end

function Keybind:_save()
	return self.value and Serialize(self.value) or "None"
end

function Keybind:_load(value)
	self:Set(Deserialize(value))
end

-- Color picker ----------------------------------------------------------------

local ColorPicker = ElementClass()

function Elements.ColorPicker(holder, p)
	local self = NewElement(ColorPicker, holder, p, "ColorPicker", 18)
	local window = self.window
	self.callback = Pick(p, nil, "callback")
	self.value = ToColor3(Pick(p, nil, "color", "value", "default"), Color3.new(1, 1, 1))
	self.alpha = math.clamp(tonumber(Pick(p, 1, "alpha", "transparency")) or 1, 0, 1)
	self.h, self.s, self.v = self.value:ToHSV()
	self.Color = self.value

	local outer, inner = window:_box(self.row, UDim2.fromOffset(24, 12), UDim2.new(1, -24, 0.5, -6), "Element")
	self._swatchOuter = outer
	Create("UIGradient", { Rotation = 90, Color = ColorSequence.new(RGB(70, 70, 70), RGB(40, 40, 40)), Parent = inner })
	self._swatch = window:_frame({ Size = UDim2.fromScale(1, 1), Parent = inner })
	self:_reserve(30)

	local hitbox = window:_hitbox(self.row, 3)
	Hover(window, hitbox, function()
		if not self._locked then
			window:_paint(outer, { BackgroundColor3 = "BorderLight" })
		end
	end, function()
		window:_paint(outer, { BackgroundColor3 = "Outline" })
	end, self)
	self:_connect(hitbox.Activated, function()
		if self._locked then
			return
		end
		if self._open then
			window:_closePopover()
		else
			self:_openPicker()
		end
	end)

	self._onRemove = function()
		if self._open then
			window:_closePopover()
		end
	end

	self:_renderSwatch()
	Register(self, p)
	return Mount(self, 20)
end

function ColorPicker:_renderSwatch()
	self._swatch.BackgroundColor3 = self.value
	self._swatch.BackgroundTransparency = 1 - self.alpha
	if self._renderPicker then
		self._renderPicker()
	end
end

function ColorPicker:_emit(skipCallback, quiet)
	self.Color = self.value
	self:_renderSwatch()
	if not skipCallback then
		Call(self.callback, self.value, self.alpha)
	end
	if not quiet then
		self:_changed()
	end
end

function ColorPicker:_openPicker()
	local window = self.window
	local outer, fill = window:_rim({ Name = "ColorPicker", Size = UDim2.fromOffset(196, 0), ZIndex = 2 }, "Panel")
	local canvas = window:_frame({ Size = UDim2.fromOffset(194, 196), BackgroundTransparency = 1, Parent = fill })

	-- Saturation / value square
	local svOuter = window:_frame({ Size = UDim2.fromOffset(152, 152), Position = UDim2.fromOffset(6, 6), Parent = canvas }, { BackgroundColor3 = "Outline" })
	local sv = window:_frame({ Size = UDim2.new(1, -2, 1, -2), Position = UDim2.fromOffset(1, 1), Parent = svOuter })
	local white = window:_frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = sv })
	Create("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = white })
	local black = window:_frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Parent = sv })
	Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = black })
	local svCursor = window:_frame({ Size = UDim2.fromOffset(4, 4), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = sv })
	Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Parent = svCursor })

	-- Hue bar
	local hueOuter = window:_frame({ Size = UDim2.fromOffset(14, 152), Position = UDim2.fromOffset(166, 6), Parent = canvas }, { BackgroundColor3 = "Outline" })
	local hue = window:_frame({ Size = UDim2.new(1, -2, 1, -2), Position = UDim2.fromOffset(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = hueOuter })
	Create("UIGradient", { Rotation = 90, Color = HueSequence, Parent = hue })
	local hueCursor = window:_frame({ Size = UDim2.new(1, 2, 0, 2), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(-1, 0), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = hue })
	Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Parent = hueCursor })

	-- Alpha bar
	local alphaOuter = window:_frame({ Size = UDim2.fromOffset(174, 10), Position = UDim2.fromOffset(6, 164), Parent = canvas }, { BackgroundColor3 = "Outline" })
	local alphaBack = window:_frame({ Size = UDim2.new(1, -2, 1, -2), Position = UDim2.fromOffset(1, 1), BackgroundColor3 = RGB(60, 60, 60), Parent = alphaOuter })
	local alphaFill = window:_frame({ Size = UDim2.fromScale(1, 1), Parent = alphaBack })
	Create("UIGradient", { Transparency = NumberSequence.new(1, 0), Parent = alphaFill })
	local alphaCursor = window:_frame({ Size = UDim2.new(0, 2, 1, 2), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(0, -1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = alphaBack })
	Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Parent = alphaCursor })

	-- Hex and RGB readouts
	local hexOuter, hexInner = window:_box(canvas, UDim2.fromOffset(78, 18), UDim2.fromOffset(6, 178), "Element")
	local hexBox = window:_textbox({ Size = UDim2.new(1, -8, 1, 0), Position = UDim2.fromOffset(4, 0), TextSize = 12, Parent = hexInner })
	local rgbLabel = window:_label({ Size = UDim2.fromOffset(94, 18), Position = UDim2.fromOffset(88, 178), TextSize = 12, Parent = canvas }, "TextDim")

	local function render()
		sv.BackgroundColor3 = Color3.fromHSV(self.h, 1, 1)
		svCursor.Position = UDim2.fromScale(self.s, 1 - self.v)
		hueCursor.Position = UDim2.new(0, -1, self.h, 0)
		alphaFill.BackgroundColor3 = self.value
		alphaCursor.Position = UDim2.fromScale(self.alpha, 0)
		if not hexBox:IsFocused() then
			hexBox.Text = "#" .. self.value:ToHex()
		end
		rgbLabel.Text = string.format("%d, %d, %d", math.floor(self.value.R * 255 + 0.5), math.floor(self.value.G * 255 + 0.5), math.floor(self.value.B * 255 + 0.5))
	end

	local function relative(frame, position)
		local size = frame.AbsoluteSize
		local x = size.X > 0 and math.clamp((position.X - frame.AbsolutePosition.X) / size.X, 0, 1) or 0
		local y = size.Y > 0 and math.clamp((position.Y - frame.AbsolutePosition.Y) / size.Y, 0, 1) or 0
		return x, y
	end

	local function commit()
		self:_changed()
	end

	window:_draggable(self, window:_hitbox(sv), function(position)
		self.s, self.v = relative(sv, position)
		self.v = 1 - self.v
		self.value = Color3.fromHSV(self.h, self.s, self.v)
		self:_emit(false, true)
	end, commit)

	window:_draggable(self, window:_hitbox(hue), function(position)
		local _, y = relative(hue, position)
		self.h = math.min(y, 0.9999)
		self.value = Color3.fromHSV(self.h, self.s, self.v)
		self:_emit(false, true)
	end, commit)

	window:_draggable(self, window:_hitbox(alphaBack), function(position)
		local x = relative(alphaBack, position)
		self.alpha = math.floor(x * 100 + 0.5) / 100
		self:_emit(false, true)
	end, commit)

	hexBox.FocusLost:Connect(function()
		local color = ToColor3(hexBox.Text)
		if color then
			self:Set(color)
		else
			render()
		end
	end)

	self._renderPicker = render
	render()
	self._open = true
	window:_openPopover(outer, self._swatchOuter, function()
		self._open = false
		self._renderPicker = nil
	end, true)
end

function ColorPicker:Set(color, skipCallback)
	color = ToColor3(color, self.value)
	local changed = color ~= self.value
	self.value = color
	local h, s, v = color:ToHSV()
	if s > 0 and v > 0 then
		self.h = h
	end
	self.s, self.v = s, v
	self:_emit(skipCallback, not changed)
end

function ColorPicker:SetAlpha(alpha, skipCallback)
	alpha = math.clamp(tonumber(alpha) or 1, 0, 1)
	local changed = alpha ~= self.alpha
	self.alpha = alpha
	self:_emit(skipCallback, not changed)
end

function ColorPicker:_save()
	return { __type = "Color3", hex = self.value:ToHex(), alpha = self.alpha }
end

function ColorPicker:_load(value)
	if type(value) == "table" and value.hex then
		self.alpha = math.clamp(tonumber(value.alpha) or 1, 0, 1)
		self:Set(Color3.fromHex(value.hex))
	elseif typeof(value) == "Color3" then
		self:Set(value)
	end
end

-- Stat ------------------------------------------------------------------------

local Stat = ElementClass()

function Elements.Stat(holder, p)
	local compact = Pick(p, false, "compact") == true or holder.kind == "row"
	if compact and Pick(p, nil, "description", "desc") then
		warn("[Onyx] descriptions are dropped on compact stats")
		p.description, p.desc = nil, nil
	end
	local self = NewElement(Stat, holder, p, "Stat", compact and 18 or 15)
	local window = self.window
	self.compact = compact
	self.prefix = tostring(Pick(p, "", "prefix"))
	self.suffix = tostring(Pick(p, "", "suffix"))
	self.display = Pick(p, "value", "display")
	self.changeMode = Pick(p, "percentage", "changemode")
	self.changeBaseline = Pick(p, "previous", "changebaseline")
	self.easing = Pick(p, true, "numbereasing") ~= false
	self.value = tonumber(Pick(p, 0, "value", "default")) or 0
	self._baseline = self.value
	self._shown = self.value

	self._change = window:_label({
		Name = "Change",
		Size = UDim2.new(0, 70, 1, 0),
		Position = UDim2.new(1, -70, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 12,
		Parent = self.row,
	}, "TextDim")

	if compact then
		self._number = self._change
		self:_reserve(74)
	else
		self:_reserve(74)
		local slot = self:_slot(20, 3)
		self._number = window:_label({
			Name = "Number",
			Size = UDim2.fromScale(1, 1),
			TextSize = 18,
			Position = UDim2.fromOffset(self._inset, 0),
			Parent = slot,
		}, "Text")
	end

	self._easer = Instance.new("NumberValue")
	self._easer.Value = self.value
	self:_connect(self._easer.Changed, function(value)
		self._shown = value
		self:_render()
	end)

	self:_render()
	return Mount(self, compact and 20 or 40)
end

function Stat:_formatValue(value)
	if self.value == math.floor(self.value) then
		value = math.floor(value + 0.5)
	else
		value = math.floor(value * 100 + 0.5) / 100
	end
	return self.prefix .. FormatNumber(value) .. self.suffix
end

function Stat:_formatChange()
	local delta = self.value - self._baseline
	if delta == 0 then
		return "0" .. (self.changeMode == "percentage" and "%" or ""), "TextDim"
	end
	local sign = delta > 0 and "+" or "-"
	local token = delta > 0 and "Success" or "Error"
	if self.changeMode == "absolute" or self._baseline == 0 then
		return sign .. FormatNumber(math.abs(delta)), token
	end
	local percent = math.abs(delta) / math.abs(self._baseline) * 100
	return sign .. FormatNumber(math.floor(percent * 10 + 0.5) / 10) .. "%", token
end

function Stat:_render()
	local window = self.window
	local changeText, changeToken = self:_formatChange()
	if self.compact then
		if self.display == "change" then
			self._number.Text = changeText
			window:_paint(self._number, { TextColor3 = changeToken })
		else
			self._number.Text = self:_formatValue(self._shown)
			window:_paint(self._number, { TextColor3 = "Text" })
		end
	else
		self._number.Text = self:_formatValue(self._shown)
		self._change.Text = changeText
		window:_paint(self._change, { TextColor3 = changeToken })
	end
end

function Stat:Set(value)
	value = tonumber(value) or 0
	if self.changeBaseline ~= "initial" then
		self._baseline = self.value
	end
	self.value = value
	if self.easing then
		Tween(self._easer, { Value = value }, 0.45, Enum.EasingStyle.Quart)
	else
		self._easer.Value = value
	end
	self:_render()
end

function Stat:ResetBaseline(value)
	self._baseline = tonumber(value) or self.value
	self:_render()
end

-- Progress --------------------------------------------------------------------

local Progress = ElementClass()

function Elements.Progress(holder, p)
	local self = NewElement(Progress, holder, p, "Progress", 15)
	local window = self.window
	local steps = tonumber(Pick(p, nil, "steps"))
	if steps and steps < 2 then
		steps = nil
	end
	self.steps = steps and math.floor(steps)
	local range = Pick(p, nil, "range") or (self.steps and { 0, self.steps }) or { 0, 1 }
	self.min, self.max = tonumber(range[1]) or 0, tonumber(range[2]) or 1
	self.text = Pick(p, nil, "text")
	self.format = Pick(p, nil, "format")
	self.showValue = Pick(p, true, "showvalue") ~= false
	self.value = math.clamp(tonumber(Pick(p, nil, "value", "default")) or self.min, self.min, self.max)

	self._readout = window:_label({
		Size = UDim2.new(0, 120, 1, 0),
		Position = UDim2.new(1, -120, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 12,
		Parent = self.row,
	}, "TextDim")
	self:_reserve(124)

	local slot = self:_slot(6, 3)
	if self.steps then
		local track = window:_frame({ Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = slot })
		List(track, 2, Enum.FillDirection.Horizontal)
		self._segments = {}
		for i = 1, self.steps do
			local outer, inner = window:_box(track, UDim2.new(1 / self.steps, -2 + 2 / self.steps, 1, 0), nil, "Element")
			outer.LayoutOrder = i
			self._segments[i] = inner
		end
	else
		local outer, inner = window:_box(slot, UDim2.fromScale(1, 1), nil, "Element")
		inner.ClipsDescendants = true
		self._track = inner
		self._fill = window:_frame({ Size = UDim2.fromScale(0, 1), Parent = inner }, { BackgroundColor3 = "Accent" })
		Create("UIGradient", { Rotation = 90, Color = Shine, Parent = self._fill })
	end

	self._onRemove = function()
		self:_stopSweep()
	end

	self:_render()
	if Pick(p, false, "indeterminate") == true then
		self:SetIndeterminate(true)
	end
	return Mount(self, 26)
end

function Progress:GetPercentage()
	local span = self.max - self.min
	if span <= 0 then
		return 0
	end
	return math.clamp((self.value - self.min) / span, 0, 1)
end

function Progress:Get()
	return self.value
end

function Progress:_render()
	local window = self.window
	local alpha = self:GetPercentage()
	if self._segments then
		local filled = math.floor(alpha * self.steps + 0.5)
		for i, segment in ipairs(self._segments) do
			window:_paint(segment, { BackgroundColor3 = (i <= filled and not self.indeterminate) and "Accent" or "Element" })
		end
	elseif not self.indeterminate then
		Tween(self._fill, { Size = UDim2.fromScale(alpha, 1), Position = UDim2.fromScale(0, 0) }, 0.2)
	end

	local readout = ""
	if self.text then
		readout = window:_t(self.text)
	elseif self.indeterminate then
		readout = "..."
	elseif type(self.format) == "function" then
		local ok, result = pcall(self.format, self.value, self.min, self.max)
		readout = ok and tostring(result) or "?"
	else
		readout = FormatNumber(math.floor(alpha * 100 + 0.5)) .. "%"
	end
	self._readout.Text = readout
	self._readout.Visible = self.showValue
end

function Progress:_stopSweep()
	if self._sweep then
		self._sweep:Disconnect()
		self._sweep = nil
	end
end

function Progress:SetIndeterminate(state)
	self.indeterminate = state == true
	self:_stopSweep()
	if self.indeterminate then
		if self._fill then
			self._fill.Size = UDim2.fromScale(0.3, 1)
			local started = os.clock()
			self._sweep = RunService.RenderStepped:Connect(function()
				local t = ((os.clock() - started) * 0.9) % 1.3
				self._fill.Position = UDim2.fromScale(t - 0.3, 0)
			end)
		elseif self._segments then
			local started = os.clock()
			self._sweep = RunService.RenderStepped:Connect(function()
				local active = math.floor((os.clock() - started) * 8) % #self._segments + 1
				for i, segment in ipairs(self._segments) do
					segment.BackgroundColor3 = i == active and self.window.Theme.Accent or self.window.Theme.Element
				end
			end)
		end
	end
	self:_render()
end

function Progress:Set(value)
	self.value = math.clamp(tonumber(value) or self.min, self.min, self.max)
	if self.indeterminate then
		self:SetIndeterminate(false)
	else
		self:_render()
	end
end

function Progress:SetRange(min, max)
	self.min, self.max = math.min(min, max), math.max(min, max)
	self.value = math.clamp(self.value, self.min, self.max)
	self:_render()
end

function Progress:SetText(text)
	self.text = text
	self:_render()
end

-- Console ---------------------------------------------------------------------

local Console = ElementClass()

function Elements.Console(holder, p)
	local hasName = Pick(p, nil, "name", "title") ~= nil
	local self = NewElement(Console, holder, p, "Console", hasName and 15 or 0)
	local window = self.window
	self.follow = Pick(p, false, "follow") == true
	self.maxLines = math.max(1, tonumber(Pick(p, 200, "maxlines")) or 200)
	self.height = math.max(48, tonumber(Pick(p, 120, "height")) or 120)
	self.lines = {}

	self._slotFrame = self:_slot(self.height, 3)
	local outer, inner = window:_box(self._slotFrame, UDim2.fromScale(1, 1), nil, "Background")
	inner:FindFirstChildOfClass("UIGradient"):Destroy()

	self._scroller = Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -8, 1, -8),
		Position = UDim2.fromOffset(4, 4),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = AUTO_Y,
		ScrollBarThickness = 2,
		Parent = inner,
	})
	window:_paint(self._scroller, { ScrollBarImageColor3 = "Accent" })
	self._body = window:_label({
		Size = UDim2.new(1, -4, 0, 0),
		AutomaticSize = AUTO_Y,
		TextSize = 12,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = self._scroller,
	}, "Text")
	self._body.RichText = false

	local copy = Create("TextButton", {
		Text = "copy",
		TextSize = 11,
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(32, 14),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -6, 0, 3),
		ZIndex = 3,
		Parent = inner,
	})
	window:_paint(copy, { TextColor3 = "Placeholder", FontFace = "Font" })
	self:_connect(copy.Activated, function()
		local ok = self:Copy()
		copy.Text = ok and "copied" or "n/a"
		task.delay(1.2, function()
			copy.Text = "copy"
		end)
	end)

	self:Set(tostring(Pick(p, "", "text", "code", "value")))
	return Mount(self, self.height + (hasName and 18 or 2))
end

function Console:_render()
	self._body.Text = table.concat(self.lines, "\n")
	if self.follow then
		task.defer(function()
			local scroller = self._scroller
			local maxY = math.max(0, scroller.AbsoluteCanvasSize.Y - scroller.AbsoluteWindowSize.Y)
			scroller.CanvasPosition = Vector2.new(0, maxY)
		end)
	end
end

function Console:_push(text)
	for line in string.gmatch(tostring(text) .. "\n", "(.-)\r?\n") do
		table.insert(self.lines, line)
	end
	while #self.lines > self.maxLines do
		table.remove(self.lines, 1)
	end
end

function Console:Set(text)
	self.lines = {}
	if text ~= nil and text ~= "" then
		self:_push(text)
	end
	self:_render()
end

function Console:Append(line)
	self:_push(line == nil and "" or line)
	self:_render()
end

function Console:Clear()
	self.lines = {}
	self:_render()
end

function Console:Get()
	return table.concat(self.lines, "\n")
end

function Console:Copy()
	return SetClipboard(self:Get())
end

function Console:SetHeight(height)
	self.height = math.max(48, tonumber(height) or self.height)
	self._slotFrame.Size = UDim2.new(1, 0, 0, self.height)
end

-- Text ------------------------------------------------------------------------

local Text = ElementClass()

function Elements.Text(holder, p)
	local self = NewElement(Text, holder, p, "Text", 0)
	local window = self.window
	self.name = Pick(p, "", "name", "title")
	self.text = Pick(p, "", "text", "content", "body")

	local stack = window:_frame({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = AUTO_Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = self.stack,
	})
	List(stack, 2)

	self._title, self._titleRow = window:_iconText(stack, {
		image = IconImage(Pick(p, nil, "icon", "image")),
		order = 1,
	})
	self._body = window:_label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = AUTO_Y,
		TextSize = 12,
		TextWrapped = true,
		LayoutOrder = 2,
		Parent = stack,
	}, "TextDim")

	self:_render()
	local estimate = 16 + math.ceil(#tostring(self.text) / 38) * 14
	return Mount(self, estimate)
end

function Text:_render()
	local window = self.window
	self._titleRow.Visible = self.name ~= nil and self.name ~= ""
	self._body.Visible = self.text ~= nil and self.text ~= ""
	window:_text(self._title, tostring(self.name or ""))
	window:_text(self._body, tostring(self.text or ""))
end

function Text:Set(text)
	if type(text) == "table" then
		local p = LowerKeys(text)
		self.name = Pick(p, self.name, "title", "name")
		self.text = Pick(p, self.text, "content", "text")
	else
		self.text = text == nil and "" or tostring(text)
	end
	self:_render()
end

function Text:SetTitle(title)
	self.name = title == nil and "" or tostring(title)
	self:_render()
end

-- Divider ---------------------------------------------------------------------

local Divider = ElementClass()

function Elements.Divider(holder, p)
	local self = NewElement(Divider, holder, p, "Divider", 0)
	local window = self.window
	self.spacing = tonumber(Pick(p, 12, "spacing")) or 12
	self.line = Pick(p, true, "line") ~= false
	self.text = tostring(Pick(p, "", "text", "name") or "")

	local slot = self:_slot(14 + self.spacing, 1)
	self._slotFrame = slot
	local middle = window:_frame({
		Size = UDim2.new(1, 0, 0, 14),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		BackgroundTransparency = 1,
		Parent = slot,
	})
	self._left = window:_frame({ AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Parent = middle }, { BackgroundColor3 = "Border" })
	self._right = window:_frame({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Parent = middle }, { BackgroundColor3 = "Border" })
	self._word = window:_label({
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 12,
		Parent = middle,
	}, "Placeholder")
	self:_connect(self._word:GetPropertyChangedSignal("TextBounds"), function()
		self:_layout()
	end)
	self:_render()
	return Mount(self, 14 + self.spacing)
end

function Divider:_layout()
	local hasText = self.text ~= ""
	local gap = hasText and (self._word.TextBounds.X / 2 + 8) or 0
	local size = UDim2.new(0.5, -gap, 0, 1)
	self._left.Size = size
	self._right.Size = size
	self._left.Visible = self.line
	self._right.Visible = self.line
end

function Divider:_render()
	self._word.Text = self.window:_t(self.text)
	self._word.Visible = self.text ~= ""
	self._slotFrame.Size = UDim2.new(1, 0, 0, self.spacing + (self.text ~= "" and 14 or 1))
	self:_layout()
end

function Divider:Set(text)
	self.text = text == nil and "" or tostring(text)
	self:_render()
end

-- Sub header ------------------------------------------------------------------

local SubHeader = ElementClass()

function Elements.SubHeader(holder, p)
	local self = NewElement(SubHeader, holder, p, "SubHeader", 18)
	self.window:_paint(self._label, { TextColor3 = "TextDim" })
	self._label.TextSize = 12
	return Mount(self, 20)
end

function SubHeader:Set(name)
	self.name = name
	self.window:_text(self._label, name)
end

-- Status row (settings tab) ------------------------------------------------------

local StatusRow = ElementClass()

function Elements.StatusRow(holder, p)
	local self = NewElement(StatusRow, holder, p, "StatusRow", 18)
	local window = self.window
	self._value = window:_label({
		Size = UDim2.new(0, 110, 1, 0),
		Position = UDim2.new(1, -110, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 12,
		Parent = self.row,
	}, "Text")
	self._dot = window:_frame({ Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(1, 0.5), Parent = self.row })
	self:_reserve(124)
	self:_connect(self._value:GetPropertyChangedSignal("TextBounds"), function()
		self._dot.Position = UDim2.new(1, -(self._value.TextBounds.X + 6), 0.5, 0)
	end)
	return Mount(self, 20)
end

function StatusRow:Set(status)
	self.root.Visible = status ~= nil
	if not status then
		return
	end
	local function color()
		return status.color
	end
	self._value.Text = string.upper(status.text)
	self.window:_paint(self._value, { TextColor3 = color })
	self.window:_paint(self._dot, { BackgroundColor3 = color })
	self._dot.Position = UDim2.new(1, -(self._value.TextBounds.X + 6), 0.5, 0)
	self.description = status.note
	self:_setDescription(status.note)
end

--------------------------------------------------------------------------------
-- Holders: sections (group boxes) and groups
--------------------------------------------------------------------------------

local Holder = {}
Holder.__index = Holder

local RowForbidden = {
	Input = true, Keybind = true, ColorPicker = true, Dropdown = true,
	Text = true, Divider = true, Console = true, Progress = true, SubHeader = true,
}

local function DefineCreators(target, resolve)
	local function creator(kind)
		return function(self, props)
			if type(props) == "string" then
				props = { name = props }
			end
			local holder = resolve(self)
			local p = LowerKeys(props)
			if holder.kind == "row" and RowForbidden[kind] then
				warn("[Onyx] " .. kind .. " cannot be placed in a row group")
				return nil
			end
			return Elements[kind](holder, p)
		end
	end
	target.CreateButton = creator("Button")
	target.CreateToggle = creator("Toggle")
	target.CreateSwitch = target.CreateToggle
	target.CreateSlider = creator("Slider")
	target.CreateDropdown = creator("Dropdown")
	target.CreateInput = creator("Input")
	target.CreateKeybind = creator("Keybind")
	target.CreateColorPicker = creator("ColorPicker")
	target.CreateStat = creator("Stat")
	target.CreateProgress = creator("Progress")
	target.CreateConsole = creator("Console")
	target.CreateText = creator("Text")
	target.CreateDivider = creator("Divider")
	target.CreateParagraph = function(self, props)
		local p = LowerKeys(props)
		return target.CreateText(self, { name = Pick(p, nil, "title", "name"), text = Pick(p, nil, "content", "text") })
	end
	target.CreateLabel = function(self, text, icon)
		if type(text) == "table" then
			return target.CreateText(self, text)
		end
		return target.CreateText(self, { text = text, icon = icon })
	end
end

DefineCreators(Holder, function(self)
	return self
end)

function Holder:_add(element, estimate)
	table.insert(self.children, element)
	element.root.LayoutOrder = #self.children
	element.root.Parent = self.content
	if self.kind == "row" then
		self:_layoutRow()
		if (#self.children - 1) % self.perRow == 0 then
			self:_grow(estimate)
		end
	else
		self:_grow(estimate + 4)
	end
end

function Holder:_grow(amount)
	self.estimate = (self.estimate or 0) + amount
	if self.parentHolder then
		self.parentHolder:_grow(amount)
	elseif self.column then
		self.column.estimate = self.column.estimate + amount
	end
end

function Holder:_layoutRow()
	local count = math.max(1, math.min(#self.children, self.perRow))
	local gap = 6
	-- -1 so rounding doesn't wrap the last cell
	for _, child in ipairs(self.children) do
		child.root.Size = UDim2.new(1 / count, -gap * (count - 1) / count - 1, 0, 0)
	end
end

function Holder:_childRemoved()
	if self.kind == "row" then
		self:_layoutRow()
	end
end

function Holder:CreateSection(props)
	local p = type(props) == "string" and { name = props } or LowerKeys(props)
	return Elements.SubHeader(self, p)
end

function Holder:CreateGroup(props)
	local p = LowerKeys(props)
	local direction = string.lower(tostring(Pick(p, "row", "direction")))
	local kind = (direction == "column" or direction == "vertical") and "column" or "row"
	local window = self.window

	local group = setmetatable({
		window = window,
		kind = kind,
		children = {},
		perRow = math.max(1, tonumber(Pick(p, 3, "perrow", "columns")) or 3),
		parentHolder = self,
		_connections = {},
	}, Holder)

	local frame = window:_frame({
		Name = "Group",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = AUTO_Y,
		BackgroundTransparency = 1,
	})
	group.root = frame
	group.content = frame
	group.holder = self
	group._onRemove = function()
		for _, child in ipairs(CopyList(group.children)) do
			child:Remove()
		end
	end
	if kind == "row" then
		List(frame, 6, Enum.FillDirection.Horizontal, { Wraps = true, VerticalAlignment = Enum.VerticalAlignment.Top })
	else
		List(frame, 6)
	end
	setmetatable(group, {
		__index = function(_, key)
			return Holder[key] or Element[key]
		end,
	})

	if self.kind == "row" then
		table.insert(self.children, group)
		frame.LayoutOrder = #self.children
		frame.Parent = self.content
		self:_layoutRow()
	else
		table.insert(self.children, group)
		frame.LayoutOrder = #self.children
		frame.Parent = self.content
	end
	return group
end

-- Section (group box) ---------------------------------------------------------

local Section = setmetatable({}, { __index = Holder })
Section.__index = Section

function Section.new(tab, column, p)
	local window = tab.window
	local self = setmetatable({
		window = window,
		tab = tab,
		kind = "box",
		children = {},
		column = column,
		holder = column,
		name = Pick(p, "", "name", "title"),
		estimate = 0,
		_connections = {},
	}, Section)

	local outer, fill = window:_rim({ Name = "Section", Size = UDim2.new(1, 0, 0, 0) }, "Panel")
	self.root = outer
	List(fill, 0)

	local header = window:_frame({ Name = "Header", Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 1, Parent = fill })
	local inset = 8
	local image = IconImage(Pick(p, nil, "icon", "image"))
	if image then
		local icon = Create("ImageLabel", {
			Image = image,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(12, 12),
			Position = UDim2.new(0, 8, 0.5, -6),
			Parent = header,
		})
		window:_paint(icon, { ImageColor3 = "Accent" })
		inset = 24
	end
	self._title = window:_label({ Size = UDim2.new(1, -inset, 1, 0), Position = UDim2.fromOffset(inset, 0), Parent = header }, "Text")
	window:_text(self._title, self.name)
	self._header = header

	local divider = window:_frame({ Size = UDim2.new(1, -16, 0, 1), Position = UDim2.new(0, 8, 1, -1), Parent = header }, { BackgroundColor3 = "Border" })
	self._divider = divider

	local content = window:_frame({
		Name = "Content",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = AUTO_Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = fill,
	})
	Padding(content, 8, 8, 8, 8)
	List(content, 6)
	self.content = content

	if self.name == "" then
		header.Visible = false
	end

	table.insert(column.children, self)
	outer.LayoutOrder = #column.children
	outer.Parent = column.frame
	column.estimate = column.estimate + 30
	tab:_layoutColumns()
	return self
end

function Section:Set(name)
	self.name = name or ""
	self.window:_text(self._title, self.name)
	self._header.Visible = self.name ~= ""
end

function Section:Remove()
	for _, child in ipairs(CopyList(self.children)) do
		if child.Remove then
			child:Remove()
		end
	end
	local index = IndexOf(self.column.children, self)
	if index then
		table.remove(self.column.children, index)
	end
	if self.tab._current == self then
		self.tab._current = nil
	end
	self.column.estimate = math.max(0, self.column.estimate - self.estimate - 30)
	self.root:Destroy()
	self.tab:_layoutColumns()
end

Section.Destroy = Section.Remove
Section.MoveTo = Element.MoveTo
Section.MoveToTop = Element.MoveToTop
Section.MoveToBottom = Element.MoveToBottom
Section.MoveUp = Element.MoveUp
Section.MoveDown = Element.MoveDown

--------------------------------------------------------------------------------
-- Tabs
--------------------------------------------------------------------------------

local Tab = {}
Tab.__index = Tab

DefineCreators(Tab, function(self)
	return self:_holder()
end)

function Tab:_holder()
	if not self._current then
		self._current = Section.new(self, self.columns[1], { name = "" })
	end
	return self._current
end

function Tab:_layoutColumns()
	local visible = {}
	for _, column in ipairs(self.columns) do
		local used = #column.children > 0
		column.frame.Visible = used
		if used then
			table.insert(visible, column)
		end
	end
	local count = math.max(1, #visible)
	for _, column in ipairs(visible) do
		column.frame.Size = UDim2.new(1 / count, -8 * (count - 1) / count, 0, 0)
	end
end

function Tab:CreateSection(props)
	local p = type(props) == "string" and { name = props } or LowerKeys(props)
	local side = Pick(p, nil, "side", "column")
	local column
	if side ~= nil then
		local index = side
		if type(side) == "string" then
			index = string.lower(side) == "right" and 2 or 1
		end
		column = self.columns[math.clamp(tonumber(index) or 1, 1, #self.columns)]
	else
		column = self.columns[1]
		for _, candidate in ipairs(self.columns) do
			if candidate.estimate < column.estimate - 1 then
				column = candidate
			end
		end
	end
	local section = Section.new(self, column, p)
	self._current = section
	return section
end

function Tab:CreateGroup(props)
	return self:_holder():CreateGroup(props)
end

function Tab:Select(noAnimation)
	local window = self.window
	if window._activeTab and window._activeTab ~= self then
		window._activeTab:Deselect(true)
	end
	window._activeTab = self
	window:_closePopover()
	self.page.Visible = true
	self:_paintButton(true, noAnimation)
	if not noAnimation then
		self.page.Position = UDim2.fromOffset(0, 6)
		Tween(self.page, { Position = UDim2.new() }, 0.18)
	else
		self.page.Position = UDim2.new()
	end
end

function Tab:Deselect(noAnimation)
	self.page.Visible = false
	self:_paintButton(false, noAnimation)
	if self.window._activeTab == self then
		self.window._activeTab = nil
	end
end

function Tab:_paintButton(active, instant)
	local window = self.window
	window:_paint(self._buttonLabel, { TextColor3 = active and "Text" or "TextDim" }, not instant)
	if self._buttonIcon then
		window:_paint(self._buttonIcon, { ImageColor3 = active and "Accent" or "TextDim" }, not instant)
	end
	self._indicator.Visible = active
	if self._buttonBack then
		self._buttonBack.BackgroundTransparency = active and 0 or 1
	end
end

function Tab:Remove()
	local window = self.window
	local index = IndexOf(window._tabs, self)
	if index then
		table.remove(window._tabs, index)
	end
	self.button:Destroy()
	self.page:Destroy()
	window:_layoutTabs()
	if window._activeTab == self then
		window._activeTab = nil
		local nextTab = window:_firstTab()
		if nextTab then
			nextTab:Select(true)
		end
	end
end

Tab.Destroy = Tab.Remove

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

local Window = {}
Window.__index = Window

local HEADER_HEIGHT = 30
local TABSTRIP_HEIGHT = 24
local RAIL_WIDTH = 150

-- Theme painting ---------------------------------------------------------------

function Window:_resolve(token)
	if type(token) == "function" then
		return token(self.Theme)
	end
	return self.Theme[token]
end

function Window:_paint(instance, map, animate)
	local entry = self._themed[instance]
	if not entry then
		entry = {}
		self._themed[instance] = entry
	end
	local goals
	for property, token in pairs(map) do
		entry[property] = token
		local value = self:_resolve(token)
		if animate and typeof(value) == "Color3" then
			goals = goals or {}
			goals[property] = value
		else
			instance[property] = value
		end
	end
	if goals then
		Tween(instance, goals, 0.15)
	end
	return instance
end

function Window:_t(raw)
	if raw == nil then
		return ""
	end
	raw = tostring(raw)
	if type(self._translator) == "function" then
		local ok, result = pcall(self._translator, raw, self.locale)
		if ok and type(result) == "string" then
			return result
		end
	end
	local locale = string.lower(tostring(self.locale or ""))
	local tables = self._translations
	local exact = tables[locale]
	if exact and exact[raw] then
		return exact[raw]
	end
	local base = tables[string.match(locale, "^(%a+)") or ""]
	if base and base[raw] then
		return base[raw]
	end
	return raw
end

function Window:_text(instance, raw, property)
	property = property or "Text"
	local entry = self._texts[instance]
	if not entry then
		entry = {}
		self._texts[instance] = entry
	end
	entry[property] = raw
	instance[property] = self:_t(raw)
end

-- Instance builders -------------------------------------------------------------

function Window:_frame(props, map)
	local frame = Create("Frame", props)
	frame.BorderSizePixel = 0
	if map then
		self:_paint(frame, map)
	end
	return frame
end

function Window:_label(props, colorToken)
	local label = Create("TextLabel", props)
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	if props.TextXAlignment == nil then
		label.TextXAlignment = Enum.TextXAlignment.Left
	end
	if props.TextSize == nil then
		label.TextSize = 13
	end
	if props.Text == nil then
		label.Text = ""
	end
	self:_paint(label, { TextColor3 = colorToken or "Text", FontFace = "Font" })
	return label
end

function Window:_textbox(props)
	local box = Create("TextBox", props)
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.TextXAlignment = Enum.TextXAlignment.Left
	if props.TextSize == nil then
		box.TextSize = 13
	end
	self:_paint(box, { TextColor3 = "Text", PlaceholderColor3 = "Placeholder", FontFace = "Font" })
	return box
end

function Window:_iconText(parent, options)
	local row = self:_frame({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = AUTO_Y,
		BackgroundTransparency = 1,
		LayoutOrder = options.order or 0,
		Parent = parent,
	})
	local inset = 0
	if options.image then
		Create("ImageLabel", {
			Image = options.image,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(13, 13),
			Position = UDim2.fromOffset(0, 1),
			Parent = row,
		})
		inset = 18
	end
	local label = self:_label({
		Text = options.text,
		Size = UDim2.new(1, -inset, 0, 0),
		Position = UDim2.fromOffset(inset, 0),
		AutomaticSize = AUTO_Y,
		TextSize = options.size or 13,
		TextWrapped = true,
		Parent = row,
	}, options.token or "Text")
	return label, row
end

-- invisible click area, grow = extra px top/bottom (thin stuff like slider bars)
function Window:_hitbox(parent, grow)
	grow = grow or 0
	return Create("TextButton", {
		Name = "Hitbox",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, grow * 2),
		Position = UDim2.fromOffset(0, -grow),
		ZIndex = 4,
		Parent = parent,
	})
end

-- 1px black outline + shaded fill
function Window:_box(parent, size, position, fillToken)
	local outer = self:_frame({ Size = size, Position = position or UDim2.new(), Parent = parent }, { BackgroundColor3 = "Outline" })
	local inner = self:_frame({ Name = "Fill", Size = UDim2.new(1, -2, 1, -2), Position = UDim2.fromOffset(1, 1), Parent = outer }, { BackgroundColor3 = fillToken or "Element" })
	Create("UIGradient", { Rotation = 90, Color = Shine, Parent = inner })
	return outer, inner
end

-- auto height panel, black outline + grey rim
function Window:_rim(props, fillToken)
	props.AutomaticSize = AUTO_Y
	local outer = self:_frame(props, { BackgroundColor3 = "Outline" })
	Padding(outer, 1)
	local rim = self:_frame({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, Parent = outer }, { BackgroundColor3 = "Border" })
	Padding(rim, 1)
	local fill = self:_frame({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, Parent = rim }, { BackgroundColor3 = fillToken or "Panel" })
	return outer, fill
end

function Window:_connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(self._connections, connection)
	return connection
end

-- drags go through one set of listeners per window. touch drags stick to the finger
-- that started them so the joystick thumb can't grab a slider
function Window:_draggable(owner, target, onMove, onEnd)
	local connection = target.InputBegan:Connect(function(input)
		if owner and owner._locked then
			return
		end
		if IsPointerDown(input) and not self._drag then
			local page = owner and self._activeTab and self._activeTab.page
			if page then
				page.ScrollingEnabled = false
			end
			self._drag = { move = onMove, finish = onEnd, input = input, page = page }
			onMove(PointerPosition(input))
		end
	end)
	if owner and owner._connections then
		table.insert(owner._connections, connection)
	else
		table.insert(self._connections, connection)
	end
end

-- Popovers (dropdown lists, colour pickers) ------------------------------------

function Window:_openPopover(frame, anchor, onClose, alignRight)
	self:_closePopover()
	if self._scale ~= 1 then
		Create("UIScale", { Scale = self._scale, Parent = frame })
	end
	frame.Parent = self._overlay
	local position, size = anchor.AbsolutePosition, anchor.AbsoluteSize
	local viewport = self._gui.AbsoluteSize
	local x = alignRight and (position.X + size.X - frame.AbsoluteSize.X) or position.X
	local y = position.Y + size.Y + 3
	frame.Position = UDim2.fromOffset(x, y)
	task.defer(function()
		if self._popover and self._popover.frame == frame then
			local height = frame.AbsoluteSize.Y
			local width = frame.AbsoluteSize.X
			local finalX = alignRight and (position.X + size.X - width) or position.X
			local finalY = y
			if viewport.Y > 0 and finalY + height > viewport.Y - 4 then
				finalY = position.Y - height - 3
			end
			if viewport.X > 0 then
				finalX = math.clamp(finalX, 4, math.max(4, viewport.X - width - 4))
			end
			frame.Position = UDim2.fromOffset(finalX, math.max(4, finalY))
		end
	end)
	self._popover = { frame = frame, anchor = anchor, onClose = onClose }
end

function Window:_closePopover()
	local popover = self._popover
	if not popover then
		return
	end
	self._popover = nil
	if popover.onClose then
		popover.onClose()
	end
	popover.frame:Destroy()
end

-- Flags and saving -------------------------------------------------------------

function Window:_valueChanged(element)
	if self._loading or not self._config or not self._config.autoSave or element.forgetState then
		return
	end
	local token = {}
	self._saveToken = token
	task.delay(0.75, function()
		if self._saveToken == token and not self.unloaded then
			self:Save()
		end
	end)
end

function Window:Get(flag)
	local element = self._elements[flag]
	if not element then
		return self._pending[flag] and Deserialize(self._pending[flag]) or nil
	end
	if element.kind == "Dropdown" then
		return CopyList(element.value)
	end
	return element.value
end

function Window:Set(flag, value)
	local element = self._elements[flag]
	if not element then
		return false
	end
	element:Set(value)
	return true
end

function Window:GetPath()
	local folder = "Onyx/Configurations"
	if self._config and self._config.customFolder then
		folder = folder .. "/" .. self._config.customFolder
	end
	local name = (self._config and self._config.fileName) or "config"
	return folder, folder .. "/" .. name .. ".json"
end

function Window:_configPath(name)
	local folder, default = self:GetPath()
	if name == nil or name == "" then
		return folder, default
	end
	name = string.gsub(tostring(name), "[\\/:*?\"<>|]", "_")
	return folder, folder .. "/" .. name .. ".json"
end

function Window:Save(name)
	if not FileSystem.Available() then
		return false
	end
	local folder, path = self:_configPath(name)
	local data = { version = 1, flags = {} }
	for flag, value in pairs(self._pending) do
		data.flags[flag] = value
	end
	for flag, element in pairs(self._elements) do
		if not element.forgetState and element._save then
			data.flags[flag] = element:_save()
		end
	end
	local ok, err = pcall(function()
		FileSystem.EnsureFolder(folder)
		writefile(path, HttpService:JSONEncode(data))
	end)
	if not ok then
		warn("[Onyx] could not save configuration: " .. tostring(err))
	end
	return ok
end

function Window:Load(name)
	if not FileSystem.Available() then
		return false
	end
	local _, path = self:_configPath(name)
	if not isfile(path) then
		return false
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(path))
	end)
	if not ok or type(data) ~= "table" or type(data.flags) ~= "table" then
		warn("[Onyx] configuration '" .. path .. "' is unreadable")
		return false
	end
	self._loading = true
	for flag, value in pairs(data.flags) do
		local element = self._elements[flag]
		if element and not element.forgetState then
			local success, err = pcall(element._load, element, value)
			if not success then
				warn("[Onyx] failed to load flag '" .. tostring(flag) .. "': " .. tostring(err))
			end
		elseif not element then
			self._pending[flag] = value
		end
	end
	self._loading = false
	return true
end

function Window:ListConfigs()
	local names = {}
	if not FileSystem.Available() or type(listfiles) ~= "function" then
		return names
	end
	local folder = self:GetPath()
	if not isfolder(folder) then
		return names
	end
	local ok, files = pcall(listfiles, folder)
	if not ok then
		return names
	end
	for _, file in ipairs(files) do
		local base = string.match(file, "([^/\\]+)%.json$")
		if base then
			table.insert(names, base)
		end
	end
	table.sort(names)
	return names
end

function Window:DeleteConfig(name)
	if not FileSystem.Available() or type(delfile) ~= "function" then
		return false
	end
	local _, path = self:_configPath(name)
	if not isfile(path) then
		return false
	end
	return (pcall(delfile, path))
end

-- Tabs ---------------------------------------------------------------------------

function Window:_firstTab()
	local best
	for _, tab in ipairs(self._tabs) do
		if not best or tab.order < best.order then
			best = tab
		end
	end
	return best
end

function Window:_layoutTabs()
	if self.sidebar then
		return
	end
	local count = math.max(1, #self._tabs)
	for _, tab in ipairs(self._tabs) do
		tab.button.Size = UDim2.new(1 / count, 0, 1, 0)
	end
end

function Window:CreateTab(props, icon)
	local p = type(props) == "table" and LowerKeys(props) or { name = props, icon = icon }
	local name = Pick(p, nil, "name", "title")
	local image = IconImage(Pick(p, nil, "icon", "image"))
	if name == nil and image == nil then
		name = "Tab"
	end

	self._tabCounter = self._tabCounter + 1
	local tab = setmetatable({
		window = self,
		name = name,
		order = Pick(p, nil, "_order") or self._tabCounter,
		columns = {},
	}, Tab)

	-- Button
	local button = Create("TextButton", {
		Name = tostring(name or "Tab"),
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = tab.order,
		Parent = self._tabList,
	})
	tab.button = button

	if self.sidebar then
		button.Size = UDim2.new(1, 0, 0, 24)
		tab._buttonBack = self:_frame({ Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = button }, { BackgroundColor3 = "Element" })
		Create("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), RGB(150, 150, 150)), Parent = tab._buttonBack })
		tab._indicator = self:_frame({ Size = UDim2.new(0, 2, 1, 0), Visible = false, Parent = button }, { BackgroundColor3 = "Accent" })
		local inset = 12
		if image then
			tab._buttonIcon = Create("ImageLabel", {
				Image = image,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(14, 14),
				Position = UDim2.new(0, 12, 0.5, -7),
				Parent = button,
			})
			inset = 32
		end
		tab._buttonLabel = self:_label({ Size = UDim2.new(1, -inset - 4, 1, 0), Position = UDim2.fromOffset(inset, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = button }, "TextDim")
	else
		local inner = self:_frame({ Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = button })
		List(inner, 6, Enum.FillDirection.Horizontal, { HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center })
		if image then
			tab._buttonIcon = Create("ImageLabel", {
				Image = image,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(14, 14),
				LayoutOrder = 1,
				Parent = inner,
			})
		end
		tab._buttonLabel = self:_label({ Size = UDim2.fromScale(0, 1), AutomaticSize = AUTO_X, LayoutOrder = 2, Parent = inner }, "TextDim")
		tab._indicator = self:_frame({ Size = UDim2.new(1, -16, 0, 2), Position = UDim2.new(0, 8, 1, -2), Visible = false, Parent = button }, { BackgroundColor3 = "Accent" })
	end
	self:_text(tab._buttonLabel, name or "")
	tab._buttonLabel.Visible = name ~= nil and name ~= ""

	Hover(self, button, function()
		if self._activeTab ~= tab then
			self:_paint(tab._buttonLabel, { TextColor3 = "Text" }, true)
		end
	end, function()
		if self._activeTab ~= tab then
			self:_paint(tab._buttonLabel, { TextColor3 = "TextDim" }, true)
		end
	end)
	self:_connect(button.Activated, function()
		if self._activeTab ~= tab then
			tab:Select()
		end
	end)

	-- Page
	local page = Create("ScrollingFrame", {
		Name = tostring(name or "Page"),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = AUTO_Y,
		ScrollBarThickness = 2,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.Always,
		Visible = false,
		Parent = self._pages,
	})
	self:_paint(page, { ScrollBarImageColor3 = "Accent" })
	Padding(page, 8, 6, 8, 8)
	self:_connect(page:GetPropertyChangedSignal("CanvasPosition"), function()
		self:_closePopover()
	end)
	tab.page = page

	local columnHolder = self:_frame({ Name = "Columns", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1, Parent = page })
	List(columnHolder, 8, Enum.FillDirection.Horizontal)
	local columnCount = math.clamp(tonumber(Pick(p, 2, "columns")) or 2, 1, 3)
	for i = 1, columnCount do
		local frame = self:_frame({
			Name = "Column" .. i,
			Size = UDim2.new(1 / columnCount, 0, 0, 0),
			AutomaticSize = AUTO_Y,
			BackgroundTransparency = 1,
			LayoutOrder = i,
			Visible = false,
			Parent = columnHolder,
		})
		List(frame, 8)
		tab.columns[i] = { frame = frame, children = {}, estimate = 0 }
	end

	table.insert(self._tabs, tab)
	self:_layoutTabs()
	tab:_paintButton(false, true)

	if not Pick(p, false, "_system") and not self._userTabSelected then
		self._userTabSelected = true
		tab:Select(true)
	end
	return tab
end

function Window:CreateSection(props)
	local p = type(props) == "string" and { name = props } or LowerKeys(props)
	local handle = { Remove = function() end }
	handle.Destroy = handle.Remove
	if not self.sidebar then
		return handle
	end
	self._tabCounter = self._tabCounter + 1
	local header = self:_label({
		Size = UDim2.new(1, 0, 0, 22),
		TextSize = 11,
		LayoutOrder = self._tabCounter,
		Parent = self._tabList,
	}, "Placeholder")
	Padding(header, 6, 0, 0, 8)
	self:_text(header, Pick(p, "", "name", "title"))
	handle.Remove = function()
		header:Destroy()
	end
	handle.Destroy = handle.Remove
	handle.Set = function(_, name)
		self:_text(header, name)
	end
	return handle
end

function Window:Navigate(target)
	if type(target) == "string" then
		for _, tab in ipairs(self._tabs) do
			if tab.name == target then
				target = tab
				break
			end
		end
	end
	if type(target) == "table" and target.Select then
		target:Select()
		return true
	end
	return false
end

-- Tags ---------------------------------------------------------------------------

function Window:CreateTag(props)
	local p = LowerKeys(props)
	local window = self
	local tag = { color = ToColor3(Pick(p, nil, "color"), RGB(255, 175, 15)) }

	local frame = self:_frame({
		Name = "Tag",
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = AUTO_X,
		LayoutOrder = 100 + (tonumber(Pick(p, 0, "order")) or 0),
		Parent = self._tagList,
	})
	Padding(frame, 0, 5, 0, 5)
	List(frame, 4, Enum.FillDirection.Horizontal, { VerticalAlignment = Enum.VerticalAlignment.Center })
	local icon = Create("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(10, 10), LayoutOrder = 1, Visible = false, Parent = frame })
	local label = self:_label({ Size = UDim2.fromScale(0, 1), AutomaticSize = AUTO_X, TextSize = 11, LayoutOrder = 2, Parent = frame }, "Text")
	tag.frame = frame

	function tag:SetColor(color)
		self.color = ToColor3(color, self.color)
		frame.BackgroundColor3 = self.color
		label.TextColor3 = ContrastText(self.color)
		window._themed[label] = nil
		icon.ImageColor3 = label.TextColor3
	end

	function tag:SetText(text)
		label.Text = text and window:_t(text) or ""
		label.Visible = text ~= nil and text ~= ""
	end

	function tag:SetIcon(value)
		local image = IconImage(value)
		icon.Image = image or ""
		icon.Visible = image ~= nil
	end

	function tag:Set(update)
		local u = LowerKeys(update)
		if Pick(u, nil, "color") ~= nil then
			self:SetColor(Pick(u, nil, "color"))
		end
		if Pick(u, nil, "text", "title") ~= nil then
			self:SetText(Pick(u, nil, "text", "title"))
		end
		if Pick(u, nil, "icon") ~= nil then
			self:SetIcon(Pick(u, nil, "icon"))
		end
		if Pick(u, nil, "order") ~= nil then
			frame.LayoutOrder = 100 + (tonumber(Pick(u, 0, "order")) or 0)
		end
	end

	function tag:Remove()
		frame:Destroy()
	end
	tag.Destroy = tag.Remove

	tag:SetColor(tag.color)
	tag:SetText(Pick(p, nil, "text", "title"))
	tag:SetIcon(Pick(p, nil, "icon"))
	return tag
end

-- Notifications ------------------------------------------------------------------

local function AutoDuration(...)
	local length = 0
	for i = 1, select("#", ...) do
		local text = select(i, ...)
		length = length + #tostring(text or "")
	end
	return math.clamp(3 + length / 28, 3, 9)
end

function Window:Notify(props)
	local p = LowerKeys(props)
	local title = self:_t(Pick(p, "Notification", "title"))
	local content = Pick(p, nil, "content", "text", "description")
	content = content and self:_t(content) or nil
	local duration = tonumber(Pick(p, nil, "duration", "time")) or AutoDuration(title, content)
	local image = IconImage(Pick(p, nil, "icon", "image"))

	local slot = self:_frame({ Name = "Notification", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1, Parent = self._notifyList })
	local card, fill = self:_rim({ Size = UDim2.new(1, 0, 0, 0), Position = UDim2.fromOffset(300, 0), Parent = slot }, "Panel")
	List(fill, 0)
	self:_frame({ Name = "Strip", Size = UDim2.new(0, 2, 1, 0), ZIndex = 2, Parent = card }, { BackgroundColor3 = "Accent" })

	local body = self:_frame({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1, LayoutOrder = 1, Parent = fill })
	Padding(body, 7, 10, 8, 12)
	List(body, 3)
	self:_iconText(body, { text = title, image = image, order = 1 })
	if content and content ~= "" then
		self:_label({ Text = content, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, TextSize = 12, TextWrapped = true, LayoutOrder = 2, Parent = body }, "TextDim")
	end
	local timerTrack = self:_frame({ Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 1, LayoutOrder = 2, Parent = fill })
	local timerBar = self:_frame({ Size = UDim2.fromScale(1, 1), Parent = timerTrack }, { BackgroundColor3 = "Accent" })

	local hitbox = self:_hitbox(card)
	local notification = { slot = slot }
	local hovered, closed = false, false
	local remaining = duration
	local heartbeat

	local function close()
		if closed then
			return
		end
		closed = true
		if heartbeat then
			heartbeat:Disconnect()
		end
		local index = IndexOf(self._notifications, notification)
		if index then
			table.remove(self._notifications, index)
		end
		local tween = Tween(card, { Position = UDim2.fromOffset(300, 0) }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween.Completed:Connect(function()
			slot:Destroy()
		end)
	end
	notification.close = close

	hitbox.MouseEnter:Connect(function()
		hovered = true
	end)
	hitbox.MouseLeave:Connect(function()
		hovered = false
	end)
	hitbox.Activated:Connect(close)

	heartbeat = RunService.Heartbeat:Connect(function(dt)
		if not hovered then
			remaining = remaining - dt
		end
		timerBar.Size = UDim2.fromScale(math.clamp(remaining / duration, 0, 1), 1)
		if remaining <= 0 then
			close()
		end
	end)
	table.insert(self._connections, heartbeat)

	table.insert(self._notifications, notification)
	while #self._notifications > 6 do
		self._notifications[1].close()
	end
	Tween(card, { Position = UDim2.new() }, 0.3, Enum.EasingStyle.Quart)
	return notification
end

function Window:Toast(props)
	local p = LowerKeys(props)
	local title = self:_t(Pick(p, "", "title", "text"))
	local subtitle = Pick(p, nil, "subtitle", "content")
	subtitle = subtitle and self:_t(subtitle) or nil
	local above = Pick(p, false, "subtitleabove") == true
	local bottom = string.lower(tostring(Pick(p, "Top", "position"))) == "bottom"
	local duration = tonumber(Pick(p, nil, "duration")) or AutoDuration(title, subtitle)
	local image = IconImage(Pick(p, nil, "icon", "image"))
	local avatar = tonumber(Pick(p, nil, "avatar"))

	local list = bottom and self._toastBottom or self._toastTop
	local slot = self:_frame({ Name = "Toast", Size = UDim2.fromOffset(0, 0), AutomaticSize = AUTO_XY, BackgroundTransparency = 1, Parent = list })
	local card, fill = self:_rim({ Size = UDim2.fromOffset(0, 0), Parent = slot }, "Panel")
	card.AutomaticSize = AUTO_XY
	fill.Parent.AutomaticSize = AUTO_XY
	fill.AutomaticSize = AUTO_XY
	fill.Parent.Size = UDim2.new()
	fill.Size = UDim2.new()
	Create("UISizeConstraint", { MinSize = Vector2.new(math.min(tonumber(Pick(p, 0, "minwidth")) or 0, 320), 0), MaxSize = Vector2.new(320, math.huge), Parent = card })

	List(fill, 0)
	self:_frame({ Size = UDim2.new(1, 0, 0, 1), LayoutOrder = 1, Parent = fill }, { BackgroundColor3 = "Accent" })
	local content = self:_frame({ Size = UDim2.new(), AutomaticSize = AUTO_XY, BackgroundTransparency = 1, LayoutOrder = 2, Parent = fill })
	Padding(content, 6, 12, 6, 10)
	List(content, 8, Enum.FillDirection.Horizontal, { VerticalAlignment = Enum.VerticalAlignment.Center })

	if avatar or image then
		local picture = Create("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(20, 20),
			Image = image or "",
			LayoutOrder = 1,
			Parent = content,
		})
		if avatar then
			task.spawn(function()
				local ok, url = pcall(function()
					return Players:GetUserThumbnailAsync(avatar, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
				end)
				if ok and picture.Parent then
					picture.Image = url
				end
			end)
		end
	end

	local stack = self:_frame({ Size = UDim2.new(), AutomaticSize = AUTO_XY, BackgroundTransparency = 1, LayoutOrder = 2, Parent = content })
	List(stack, 1)
	self:_label({ Text = title, Size = UDim2.new(), AutomaticSize = AUTO_XY, LayoutOrder = above and 2 or 1, Parent = stack }, "Text")
	if subtitle and subtitle ~= "" then
		self:_label({ Text = subtitle, Size = UDim2.new(), AutomaticSize = AUTO_XY, TextSize = 12, LayoutOrder = above and 1 or 2, Parent = stack }, "TextDim")
	end

	card.Position = UDim2.fromOffset(0, bottom and 40 or -40)
	Tween(card, { Position = UDim2.new() }, 0.3, Enum.EasingStyle.Quart)

	local toast = {}
	local closed = false
	function toast.close()
		if closed then
			return
		end
		closed = true
		local tween = Tween(card, { Position = UDim2.fromOffset(0, bottom and 40 or -40) }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween.Completed:Connect(function()
			slot:Destroy()
		end)
	end
	toast.Close = toast.close
	task.delay(duration, toast.close)
	return toast
end

-- Popups ---------------------------------------------------------------------------

-- footer style button. style is "neutral", "primary" (accent) or "danger"
function Window:_button(parent, text, style, order, callback)
	style = string.lower(tostring(style or "neutral"))
	local fillToken = style == "primary" and "Accent" or style == "danger" and "Error" or "Element"
	local outer, inner = self:_box(parent, UDim2.fromOffset(0, 22), nil, fillToken)
	outer.AutomaticSize = AUTO_X
	outer.LayoutOrder = order or 0
	inner.Size = UDim2.new(0, 0, 1, -2)
	inner.AutomaticSize = AUTO_X
	local label = self:_label({ Text = self:_t(text), Size = UDim2.fromScale(0, 1), AutomaticSize = AUTO_X, TextSize = 12, Parent = inner }, "Text")
	self:_paint(label, {
		TextColor3 = function(theme)
			if fillToken == "Element" then
				return theme.Text
			end
			return ContrastText(theme[fillToken])
		end,
	})
	Padding(label, 0, 12, 0, 12)
	Padding(outer, 0, 1, 0, 0)
	local hitbox = self:_hitbox(outer)
	hitbox.MouseEnter:Connect(function()
		self:_paint(outer, { BackgroundColor3 = "BorderLight" })
	end)
	hitbox.MouseLeave:Connect(function()
		self:_paint(outer, { BackgroundColor3 = "Outline" })
	end)
	hitbox.Activated:Connect(callback)
	return outer, label
end

-- keep fixed-width cards (popups, key prompt) inside small screens
function Window:_fitCard(card, width)
	local screen = self._gui.AbsoluteSize
	if screen.X > 0 and screen.X - 16 < width then
		Create("UIScale", { Scale = (screen.X - 16) / width, Parent = card })
	end
end

function Window:Popup(props)
	local p = LowerKeys(props)
	local dismissable = Pick(p, true, "dismissable", "dismissible") ~= false
	local options = Pick(p, nil, "options", "buttons") or { { text = "Close" } }
	local popup = {}
	local closed = false

	local backdrop = Create("TextButton", {
		Name = "Popup",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = self._popupLayer,
	})
	Tween(backdrop, { BackgroundTransparency = 0.45 }, 0.2)

	local card, fill = self:_rim({ Size = UDim2.fromOffset(340, 0), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Parent = backdrop }, "Panel")
	self:_frame({ Size = UDim2.new(1, 0, 0, 2), Parent = fill, LayoutOrder = 0 }, { BackgroundColor3 = "Accent" })
	List(fill, 0)
	local body = self:_frame({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1, LayoutOrder = 1, Parent = fill })
	Padding(body, 12, 14, 12, 14)
	List(body, 8)

	-- Header
	local header = self:_frame({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1, LayoutOrder = 1, Parent = body })
	List(header, 2)
	self:_iconText(header, { text = self:_t(Pick(p, "Popup", "title")), image = IconImage(Pick(p, nil, "icon")), size = 14, order = 1 })
	local subtitle = Pick(p, nil, "subtitle")
	if subtitle then
		self:_label({ Text = self:_t(subtitle), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, TextSize = 12, TextWrapped = true, LayoutOrder = 2, Parent = header }, "TextDim")
	end

	-- Body
	local scroller = Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = AUTO_Y,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = AUTO_Y,
		ScrollBarThickness = 2,
		LayoutOrder = 2,
		Parent = body,
	})
	self:_paint(scroller, { ScrollBarImageColor3 = "Accent" })
	Create("UISizeConstraint", { MaxSize = Vector2.new(math.huge, 260), Parent = scroller })
	List(scroller, 6)

	local content = Pick(p, nil, "content", "text")
	if content then
		self:_label({ Text = self:_t(content), Size = UDim2.new(1, -4, 0, 0), AutomaticSize = AUTO_Y, TextSize = 12, TextWrapped = true, LayoutOrder = 1, Parent = scroller }, "TextDim")
	end
	for index, box in ipairs(Pick(p, {}, "boxes") or {}) do
		local b = LowerKeys(box)
		local boxOuter, boxFill = self:_rim({ Size = UDim2.new(1, -4, 0, 0), LayoutOrder = 10 + index, Parent = scroller }, "Element")
		Padding(boxFill, 6, 8, 6, 8)
		List(boxFill, 2)
		self:_iconText(boxFill, {
			text = self:_t(Pick(b, "", "title")),
			image = IconImage(Pick(b, nil, "icon")),
			token = Pick(b, false, "accent") and "Accent" or "Text",
			order = 1,
		})
		local description = Pick(b, nil, "description", "content")
		if description then
			self:_label({ Text = self:_t(description), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, TextSize = 12, TextWrapped = true, LayoutOrder = 2, Parent = boxFill }, "TextDim")
		end
	end

	-- Footer
	local footer = self:_frame({ Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 3, Parent = body })
	List(footer, 6, Enum.FillDirection.Horizontal, { HorizontalAlignment = Enum.HorizontalAlignment.Right })

	function popup:Close()
		if closed then
			return
		end
		closed = true
		local window = popup._window
		local index = IndexOf(window._popups, popup)
		if index then
			table.remove(window._popups, index)
		end
		local tween = Tween(backdrop, { BackgroundTransparency = 1 }, 0.15)
		card.Visible = false
		tween.Completed:Connect(function()
			backdrop:Destroy()
		end)
	end
	popup._window = self
	popup.dismissable = dismissable

	for index, option in ipairs(options) do
		local o = LowerKeys(option)
		self:_button(footer, Pick(o, "OK", "text", "title", "name"), Pick(o, "neutral", "style"), index, function()
			Call(Pick(o, nil, "callback"))
			popup:Close()
		end)
	end

	backdrop.Activated:Connect(function(input)
		if dismissable and not Inside(card, PointerPosition(input)) then
			popup:Close()
		end
	end)
	self:_fitCard(card, 340)

	table.insert(self._popups, popup)
	return popup
end

-- Visibility -------------------------------------------------------------------------

function Window:Show()
	if self.unloaded or self._keyLocked then
		return
	end
	self.visible = true
	self._main.Visible = true
	self:_refreshPill()
end

function Window:Hide()
	if self.unloaded then
		return
	end
	self.visible = false
	self:_closePopover()
	self._main.Visible = false
	self:_refreshPill()
end

function Window:ToggleHide()
	if self.visible then
		self:Hide()
	else
		self:Show()
	end
end

function Window:ToggleMinimise()
	self.minimised = not self.minimised
	self:_closePopover()
	local goal = self.minimised and UDim2.fromOffset(self._size.X, HEADER_HEIGHT + 2) or UDim2.fromOffset(self._size.X, self._size.Y)
	Tween(self._main, { Size = goal }, 0.22)
	self._minimiseButton.Text = self.minimised and "+" or "-"
end

Window.ToggleMinimize = Window.ToggleMinimise

function Window:SetProfile(text)
	if self._profileLabel then
		self._profileLabel.Text = text and self:_t(text) or ""
		self._profileLabel.Visible = text ~= nil and text ~= ""
	end
end

function Window:IsVisible()
	return self.visible == true
end

-- Theme and language ------------------------------------------------------------------

function Window:ChangeTheme(spec)
	self.Theme = BuildTheme(spec, type(spec) == "table" and self.Theme or nil)
	for instance, properties in pairs(self._themed) do
		if instance.Parent == nil and instance ~= self._gui then
			self._themed[instance] = nil
		else
			local goals
			for property, token in pairs(properties) do
				local value = self:_resolve(token)
				if typeof(value) == "Color3" then
					goals = goals or {}
					goals[property] = value
				elseif value ~= nil then
					instance[property] = value
				end
			end
			if goals then
				Tween(instance, goals, 0.25)
			end
		end
	end
	self:_refreshAccentBar()
	local dropdown = self._themeDropdown
	if dropdown and not dropdown._removed and dropdown.value[1] ~= self.Theme.Name and IndexOf(dropdown.options, self.Theme.Name) then
		dropdown:Set(self.Theme.Name, true)
	end
end

function Window:SetLocale(locale)
	self.locale = locale
	self:_retranslate()
end

function Window:SetTranslator(translator)
	self._translator = translator
	self:_retranslate()
end

function Window:RegisterTranslations(tables)
	for locale, strings in pairs(tables or {}) do
		local key = string.lower(locale)
		self._translations[key] = self._translations[key] or {}
		for raw, translated in pairs(strings) do
			self._translations[key][raw] = translated
		end
	end
	self:_retranslate()
end

function Window:_retranslate()
	for instance, properties in pairs(self._texts) do
		if instance.Parent == nil then
			self._texts[instance] = nil
		else
			for property, raw in pairs(properties) do
				instance[property] = self:_t(raw)
			end
		end
	end
end

-- loops the palette so the scrolling bar has no seam
function Window:_refreshAccentBar(phase)
	local palette
	if self.Theme.Rainbow then
		palette = RainbowPalette
	else
		local accent = self.Theme.Accent
		local h, s, v = accent:ToHSV()
		palette = { accent, Color3.fromHSV(h, s, v * 0.45) }
	end
	phase = phase or 0
	local count = #palette
	local points = {}
	for i = 0, 8 do
		local t = i / 8
		local u = ((t * 0.5 + phase) % 1) * count
		local index = math.floor(u)
		local a = palette[index % count + 1]
		local b = palette[(index + 1) % count + 1]
		points[i + 1] = ColorSequenceKeypoint.new(t, a:Lerp(b, u - index))
	end
	self._accentGradient.Color = ColorSequence.new(points)
end

-- Lifecycle --------------------------------------------------------------------------

function Window:Unload()
	if self.unloaded then
		return
	end
	self.unloaded = true
	self._closePopoverSafe = nil
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	for _, element in pairs(self._elements) do
		for _, connection in ipairs(element._connections or {}) do
			connection:Disconnect()
		end
		if element._stopSweep then
			element:_stopSweep()
		end
	end
	self._gui:Destroy()
	local index = IndexOf(Onyx.Windows, self)
	if index then
		table.remove(Onyx.Windows, index)
	end
end

Window.Destroy = Window.Unload

-- Settings tab ------------------------------------------------------------------------

function Window:_buildSettings()
	local tab = self:CreateTab({ name = "Settings", _system = true, _order = 1e6 })
	self._settingsTab = tab

	local menu = tab:CreateSection({ name = "Menu", side = "left" })
	menu:CreateKeybind({
		name = "Menu key",
		flag = "OnyxMenuKey",
		value = self.toggleKey,
		_menuKey = true,
		onChanged = function(key)
			if key then
				self.toggleKey = key
				self:_refreshPill()
			end
		end,
	})
	local themeOptions = CopyList(ThemeNames)
	if self._customTheme then
		table.insert(themeOptions, 1, "custom")
	end
	self._themeDropdown = menu:CreateDropdown({
		name = "Theme",
		flag = "OnyxTheme",
		options = themeOptions,
		value = self.Theme.Name,
		callback = function(name)
			if name == nil or name == self.Theme.Name then
				return
			end
			if name == "custom" and self._customTheme then
				self:ChangeTheme(self._customTheme)
				self.Theme.Name = "custom"
			elseif Themes[name] then
				self:ChangeTheme(name)
			end
		end,
	})
	menu:CreateButton({
		name = "Unload",
		callback = function()
			self:Popup({
				title = "Unload interface?",
				content = "The menu and all of its keybinds will be removed.",
				options = {
					{ text = "Cancel" },
					{ text = "Unload", style = "danger", callback = function()
						self:Unload()
					end },
				},
			})
		end,
	})

	if self._config then
		local configs = tab:CreateSection({ name = "Configurations", side = "right" })
		local nameInput = configs:CreateInput({ name = "Name", placeholder = "config name", forgetState = true })
		local list = configs:CreateDropdown({ name = "Saved", options = self:ListConfigs(), forgetState = true })

		local function selected()
			local typed = nameInput.value
			if typed ~= nil and typed ~= "" then
				return typed
			end
			return list.value[1]
		end

		local function refresh()
			list:Refresh(self:ListConfigs())
		end

		local row = configs:CreateGroup({ direction = "row", perRow = 2 })
		row:CreateButton({
			name = "Save",
			callback = function()
				local name = selected()
				if not name then
					self:Toast({ title = "Enter a config name", duration = 2 })
					return
				end
				local ok = self:Save(name)
				refresh()
				self:Toast({ title = ok and "Saved" or "Save failed", subtitle = name, duration = 2 })
			end,
		})
		row:CreateButton({
			name = "Load",
			callback = function()
				local name = selected()
				local ok = name and self:Load(name)
				self:Toast({ title = ok and "Loaded" or "Nothing to load", subtitle = name, duration = 2 })
			end,
		})
		row:CreateButton({
			name = "Delete",
			callback = function()
				local name = selected()
				if not name then
					return
				end
				self:Popup({
					title = "Delete '" .. name .. "'?",
					content = "This configuration file will be removed.",
					options = {
						{ text = "Cancel" },
						{ text = "Delete", style = "danger", callback = function()
							self:DeleteConfig(name)
							refresh()
						end },
					},
				})
			end,
		})
		row:CreateButton({ name = "Refresh", callback = refresh })
		if not FileSystem.Available() then
			configs:CreateText({ text = "Your executor does not support file functions." })
		end
	end

	local info = tab:CreateSection({ name = "About", side = self._config and "right" or "left" })
	self._statusRow = Elements.StatusRow(info, { name = "Status" })
	self._statusRow:Set(self.status)
	local executor = "Unknown"
	if type(identifyexecutor) == "function" then
		local ok, name = pcall(identifyexecutor)
		if ok and name then
			executor = tostring(name)
		end
	end
	info:CreateText({ text = "Onyx " .. Onyx.Version .. "\nExecutor: " .. executor })
end

-- launcher: always visible on mobile, only while hidden on pc
function Window:_refreshPill()
	if self._pillLabel then
		if self._mobile then
			self._pillLabel.Text = self._showName
		else
			self._pillLabel.Text = self._showName .. "  [" .. KeyName(self.toggleKey) .. "]"
		end
	end
	if self._pill then
		self._pill.Visible = self._showPill and not self._keyLocked and (self._mobile or not self.visible)
		if self._pillAccent then
			self._pillAccent.Visible = self.visible
		end
	end
end

-- shrink to fit small screens
function Window:_fitToScreen()
	local screen = self._gui.AbsoluteSize
	if screen.X <= 0 or screen.Y <= 0 then
		return
	end
	local scale = self._userScale or math.min(1, (screen.X - 16) / self._size.X, (screen.Y - 16) / self._size.Y)
	scale = math.clamp(scale, 0.45, 2)
	self._scale = scale
	self._uiScale.Scale = scale
	local main = self._main
	if main.AnchorPoint.X == 0 then
		local position, size = main.AbsolutePosition, main.AbsoluteSize
		local x = math.clamp(position.X, 0, math.max(0, screen.X - size.X))
		local y = math.clamp(position.Y, 0, math.max(0, screen.Y - size.Y))
		main.Position = UDim2.fromOffset(x, y)
	end
end

-- Script status ------------------------------------------------------------------

local Statuses = {
	working = { text = "Working", color = RGB(112, 208, 92) },
	updating = { text = "Updating", color = RGB(255, 165, 40) },
	patched = { text = "Patched", color = RGB(226, 72, 72) },
}

local function ResolveStatus(state, note)
	local text, color
	if type(state) == "table" then
		local s = LowerKeys(state)
		note = Pick(s, note, "note", "description")
		text = Pick(s, nil, "text", "label")
		color = ToColor3(Pick(s, nil, "color"))
		state = Pick(s, nil, "state", "status")
	end
	local key = string.lower(tostring(state or ""))
	local preset = Statuses[key]
	if not preset and not text then
		warn("[Onyx] unknown status '" .. tostring(state) .. "' (use working, updating or patched)")
	end
	return {
		state = key,
		text = text or (preset and preset.text) or tostring(state),
		color = color or (preset and preset.color) or RGB(140, 140, 140),
		note = note,
	}
end

-- state: "working" | "updating" | "patched" | { text, color, note }. nil clears it.
function Window:SetStatus(state, note)
	if state == nil then
		self.status = nil
		if self._statusTag then
			self._statusTag:Remove()
			self._statusTag = nil
		end
		if self._statusRow then
			self._statusRow:Set(nil)
		end
		return
	end
	local status = ResolveStatus(state, note)
	self.status = status
	if self._showStatusTag then
		if self._statusTag then
			self._statusTag:Set({ text = string.lower(status.text), color = status.color })
		else
			self._statusTag = self:CreateTag({ text = string.lower(status.text), color = status.color, order = -1 })
		end
	end
	if self._statusRow then
		self._statusRow:Set(status)
	end
	return status
end

function Window:GetStatus()
	return self.status
end

-- reads a status file. accepts "patched", "updating: fixing esp" (note after a colon or on
-- the next lines) or json like {"status": "working", "note": "..."}
local function ParseStatus(body)
	body = string.gsub(tostring(body or ""), "^%s+", "")
	body = string.gsub(body, "%s+$", "")
	if body == "" then
		return nil
	end
	if string.sub(body, 1, 1) == "{" then
		local ok, data = pcall(function()
			return HttpService:JSONDecode(body)
		end)
		if ok and type(data) == "table" then
			local d = LowerKeys(data)
			return Pick(d, nil, "status", "state"), Pick(d, nil, "note", "description", "message")
		end
		return nil
	end
	local first, rest = string.match(body, "^([^\n]*)\n?(.*)$")
	local state, note = string.match(first, "^%s*([%w_]+)%s*[:%-|]%s*(.-)%s*$")
	if not state then
		state = string.match(first, "^%s*([%w_]+)")
	end
	rest = string.gsub(rest or "", "^%s+", "")
	if rest ~= "" then
		note = (note and note ~= "") and (note .. "\n" .. rest) or rest
	end
	if note == "" then
		note = nil
	end
	return state, note
end

-- pulls the status from a url (raw github file, pastebin, your api...) and optionally keeps polling
function Window:_watchStatus(url, every)
	task.spawn(function()
		local last
		while not self.unloaded do
			local ok, body = pcall(function()
				return game:HttpGet(url)
			end)
			if ok then
				local state, note = ParseStatus(body)
				local key = tostring(state) .. "\0" .. tostring(note)
				if state and key ~= last then
					last = key
					self:SetStatus(string.lower(state), note)
				end
			else
				warn("[Onyx] couldn't fetch status from " .. tostring(url))
			end
			if not every or every <= 0 then
				break
			end
			task.wait(math.max(every, 10))
		end
	end)
end

-- Notice / changelog -------------------------------------------------------------

local function SafeName(name)
	return (string.gsub(tostring(name), "[\\/:*?\"<>|]", "_"))
end

function Window:ShowNotice(props)
	if type(props) == "string" then
		props = { content = props }
	end
	local p = LowerKeys(props)
	return self:Popup({
		title = Pick(p, "Notice", "title"),
		subtitle = Pick(p, nil, "subtitle"),
		icon = Pick(p, nil, "icon"),
		content = Pick(p, "", "content", "text"),
		dismissable = Pick(p, true, "dismissable"),
		options = { { text = Pick(p, "OK", "button"), style = "primary", callback = Pick(p, nil, "callback") } },
	})
end

-- entries: { { version = "1.1", date = "...", changes = { "..." } }, ... } newest first
function Window:ShowChangelog(props)
	local p = LowerKeys(props)
	local entries = Pick(p, nil, "entries", "changes", "versions")
	if not entries and type(props) == "table" and props[1] then
		entries = props
	end
	entries = entries or {}

	local latest = entries[1] and tostring(LowerKeys(entries[1]).version or "") or ""
	local once = Pick(p, false, "once") == true
	local seenPath = "Onyx/Seen/" .. SafeName(Pick(p, self.name, "filename")) .. ".txt"
	if once and FileSystem.Available() and isfile(seenPath) then
		local ok, seen = pcall(readfile, seenPath)
		if ok and seen == latest then
			return nil
		end
	end

	local boxes = {}
	for i, entry in ipairs(entries) do
		local e = LowerKeys(entry)
		local version = tostring(e.version or "")
		if string.match(version, "^%d") then
			version = "v" .. version
		end
		local title = version
		if e.date then
			title = title .. "  " .. tostring(e.date)
		end
		local lines = {}
		for _, change in ipairs(e.changes or {}) do
			table.insert(lines, "- " .. tostring(change))
		end
		boxes[i] = {
			title = title,
			description = #lines > 0 and table.concat(lines, "\n") or e.description,
			accent = i == 1,
		}
	end

	local popup = self:Popup({
		title = Pick(p, "What's new", "title"),
		subtitle = Pick(p, latest ~= "" and ("Latest: " .. (string.match(latest, "^%d") and "v" or "") .. latest) or nil, "subtitle"),
		content = Pick(p, nil, "content", "text"),
		boxes = boxes,
		options = { { text = Pick(p, "Got it", "button"), style = "primary" } },
	})

	if once and FileSystem.Available() then
		pcall(function()
			FileSystem.EnsureFolder("Onyx/Seen")
			writefile(seenPath, latest)
		end)
	end
	return popup
end

-- Key system ---------------------------------------------------------------------

local function Trim(text)
	return (string.gsub(tostring(text or ""), "^%s*(.-)%s*$", "%1"))
end

-- Blocks until a valid key is entered. Returns false if the prompt was closed.
function Window:_runKeySystem(options)
	local o = LowerKeys(options)
	local keys = Pick(o, {}, "keys", "key")
	if type(keys) ~= "table" then
		keys = { keys }
	end
	local fromSite = Pick(o, false, "grabkeyfromsite") == true
	local validate = Pick(o, nil, "validate", "check")
	local link = Pick(o, nil, "url", "link", "keylink", "getkeylink")
	local saveKey = Pick(o, true, "savekey", "remember") ~= false
	local keyPath = "Onyx/Keys/" .. SafeName(Pick(o, self.name, "filename")) .. ".txt"

	local cached
	local function validKeys()
		if not cached then
			cached = {}
			for _, key in ipairs(keys) do
				if fromSite then
					local ok, body = pcall(function()
						return game:HttpGet(key)
					end)
					if ok and body then
						table.insert(cached, Trim(body))
					end
				else
					table.insert(cached, Trim(key))
				end
			end
		end
		return cached
	end

	local function isValid(key)
		key = Trim(key)
		if key == "" then
			return false
		end
		if type(validate) == "function" then
			local ok, result = pcall(validate, key)
			if not ok then
				warn("[Onyx] key check errored: " .. tostring(result))
			elseif result then
				return true
			end
		end
		for _, valid in ipairs(validKeys()) do
			if valid == key then
				return true
			end
		end
		return false
	end

	if saveKey and FileSystem.Available() and isfile(keyPath) then
		local ok, saved = pcall(readfile, keyPath)
		if ok and isValid(saved) then
			return true
		end
	end

	local result
	local layer = self:_frame({
		Name = "KeySystem",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		Active = true,
		ZIndex = 40,
		Parent = self._gui,
	})
	local card, fill = self:_rim({ Size = UDim2.fromOffset(340, 0), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Parent = layer }, "Panel")
	self:_fitCard(card, 340)
	List(fill, 0)
	self:_frame({ Size = UDim2.new(1, 0, 0, 2), LayoutOrder = 0, Parent = fill }, { BackgroundColor3 = "Accent" })
	local body = self:_frame({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1, LayoutOrder = 1, Parent = fill })
	Padding(body, 12, 14, 12, 14)
	List(body, 8)

	local header = self:_frame({ Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = 1, Parent = body })
	local titleRow = self:_frame({ Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1, Parent = header })
	List(titleRow, 6, Enum.FillDirection.Horizontal, { VerticalAlignment = Enum.VerticalAlignment.Center })
	self:_label({ Text = self:_t(Pick(o, self.name, "title")), Size = UDim2.fromScale(0, 1), AutomaticSize = AUTO_X, TextSize = 14, LayoutOrder = 1, Parent = titleRow }, "Accent")
	self:_label({ Text = self:_t(Pick(o, "key system", "subtitle")), Size = UDim2.fromScale(0, 1), AutomaticSize = AUTO_X, TextSize = 12, LayoutOrder = 2, Parent = titleRow }, "TextDim")
	local close = Create("TextButton", {
		Name = "Close",
		Text = "x",
		TextSize = 14,
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(20, 18),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Parent = header,
	})
	self:_paint(close, { TextColor3 = "TextDim", FontFace = "Font" })

	local note = Pick(o, nil, "note", "description")
	if note then
		self:_label({ Text = self:_t(note), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, TextSize = 12, TextWrapped = true, LayoutOrder = 2, Parent = body }, "TextDim")
	end

	local inputOuter, inputInner = self:_box(body, UDim2.new(1, 0, 0, 26), nil, "Element")
	inputOuter.LayoutOrder = 3
	local input = self:_textbox({
		Name = "Key",
		Text = "",
		PlaceholderText = self:_t(Pick(o, "enter key", "placeholder")),
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		Parent = inputInner,
	})

	local message = self:_label({ Name = "Message", Size = UDim2.new(1, 0, 0, 14), TextSize = 12, LayoutOrder = 4, Parent = body }, "TextDim")
	local function say(text, token)
		message.Text = self:_t(text)
		self:_paint(message, { TextColor3 = token or "TextDim" })
	end

	local buttons = self:_frame({ Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 5, Parent = body })
	List(buttons, 6, Enum.FillDirection.Horizontal, { HorizontalAlignment = Enum.HorizontalAlignment.Right })

	local checking = false
	local function submit()
		if checking or result ~= nil then
			return
		end
		checking = true
		say("checking...")
		local key = Trim(input.Text)
		local ok = isValid(key)
		checking = false
		if ok then
			say("key accepted", "Success")
			if saveKey and FileSystem.Available() then
				pcall(function()
					FileSystem.EnsureFolder("Onyx/Keys")
					writefile(keyPath, key)
				end)
			end
			result = true
		else
			say(key == "" and "enter a key first" or "invalid key", "Error")
			inputOuter.BackgroundColor3 = self.Theme.Error
			Tween(inputOuter, { BackgroundColor3 = self.Theme.Outline }, 0.6)
		end
	end

	if link then
		self:_button(buttons, "get key", "neutral", 1, function()
			if SetClipboard(link) then
				say("link copied to clipboard", "Success")
			else
				say(tostring(link))
			end
		end)
	end
	self:_button(buttons, "check key", "primary", 2, submit)

	input.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			submit()
		end
	end)
	close.Activated:Connect(function()
		result = false
	end)

	while result == nil and not self.unloaded do
		task.wait(0.05)
	end
	layer:Destroy()
	return result == true
end

--------------------------------------------------------------------------------
-- Window construction
--------------------------------------------------------------------------------

local function MountGui(gui)
	local mounted = false
	if type(gethui) == "function" then
		mounted = pcall(function()
			gui.Parent = gethui()
		end) and gui.Parent ~= nil
	end
	if not mounted then
		if syn and type(syn.protect_gui) == "function" then
			pcall(syn.protect_gui, gui)
		end
		mounted = pcall(function()
			gui.Parent = CoreGui
		end) and gui.Parent ~= nil
	end
	if not mounted then
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
end

function Onyx:CreateWindow(props)
	local p = LowerKeys(props)
	local window = setmetatable({}, Window)
	-- not weak tables on purpose, dead instances get cleaned up in ChangeTheme/SetLocale
	window._themed = {}
	window._texts = {}
	window._connections = {}
	window._elements = {}
	window._pending = {}
	window._tabs = {}
	window._notifications = {}
	window._popups = {}
	window._tabCounter = 0
	window.unloaded = false
	window.visible = true
	window.minimised = false

	window.name = Pick(p, "Onyx", "name", "title")
	window.subtitle = Pick(p, nil, "subtitle", "loadingsubtitle")
	window.sidebar = Pick(p, false, "sidebarlayout", "sidebar") == true
	local themeSpec = Pick(p, "default", "theme")
	window.Theme = BuildTheme(themeSpec)
	if type(themeSpec) == "table" then
		window._customTheme = themeSpec
	end
	window.toggleKey = ParseKey(Pick(p, nil, "togglekey", "toggleuikeybind", "keybind")) or Enum.KeyCode.RightShift
	window.locale = Pick(p, nil, "locale") or (LocalPlayer and LocalPlayer.LocaleId) or "en-us"
	window._translator = Pick(p, nil, "translator")
	window._translations = {}
	for locale, strings in pairs(Pick(p, {}, "translations") or {}) do
		window._translations[string.lower(locale)] = strings
	end
	window._showName = tostring(Pick(p, window.name, "showname"))
	window._showPill = Pick(p, true, "showpill") ~= false
	local mobile = Pick(p, nil, "mobile")
	if mobile == nil then
		mobile = IsTouchDevice()
	end
	window._mobile = mobile == true
	window._userScale = tonumber(Pick(p, nil, "scale"))
	window._scale = 1
	window._showStatusTag = Pick(p, true, "statustag") ~= false

	local keyOptions = Pick(p, nil, "keysystem")
	if keyOptions == true then
		keyOptions = Pick(p, {}, "keysettings")
	end
	if type(keyOptions) ~= "table" then
		keyOptions = nil
	end

	-- config saving
	local config = Pick(p, nil, "configuration", "configurationsaving")
	if type(config) == "table" then
		local c = LowerKeys(config)
		if Pick(c, true, "enabled") ~= false then
			-- old style tables (with Enabled) wait for LoadConfiguration() instead of autoloading
			local oldStyle = c.enabled ~= nil
			window._config = {
				autoSave = Pick(c, true, "autosave") ~= false,
				autoLoad = Pick(c, not oldStyle, "autoload") == true,
				fileName = tostring(Pick(c, window.name, "filename")),
				customFolder = Pick(c, nil, "customfolder", "foldername"),
			}
		end
	end

	-- size is in unscaled pixels, UIScale handles small screens
	local size = Pick(p, nil, "size")
	local width = (typeof(size) == "UDim2" and size.X.Offset) or (typeof(size) == "Vector2" and size.X) or (window.sidebar and 660 or 580)
	local height = (typeof(size) == "UDim2" and size.Y.Offset) or (typeof(size) == "Vector2" and size.Y) or 440
	window._size = Vector2.new(width, height)

	-- Root
	local gui = Create("ScreenGui", {
		Name = "Onyx",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 999,
	})
	pcall(function()
		gui.ScreenInsets = Enum.ScreenInsets.None
	end)
	window._gui = gui

	local main = window:_frame({
		Name = "Main",
		Size = UDim2.fromOffset(width, height),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Active = true,
		Parent = gui,
	}, { BackgroundColor3 = "Outline" })
	window._main = main
	window._uiScale = Create("UIScale", { Scale = 1, Parent = main })

	local edge = window:_frame({ Name = "Edge", Size = UDim2.new(1, -2, 1, -2), Position = UDim2.fromOffset(1, 1), Parent = main }, { BackgroundColor3 = "BorderLight" })
	local body = window:_frame({ Name = "Body", Size = UDim2.new(1, -2, 1, -2), Position = UDim2.fromOffset(1, 1), ClipsDescendants = true, Parent = edge }, { BackgroundColor3 = "Background" })

	-- Accent bar
	local accent = window:_frame({ Name = "Accent", Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), Parent = body })
	window._accentGradient = Create("UIGradient", { Parent = accent })
	window:_refreshAccentBar()
	local lastFrame = 0
	window:_connect(RunService.RenderStepped, function()
		local now = os.clock()
		if window.Theme.LiveAnimation and window.visible and now - lastFrame >= 1 / 30 then
			lastFrame = now
			window:_refreshAccentBar(now * 0.08)
		end
	end)

	-- Header
	local header = window:_frame({ Name = "Header", Size = UDim2.new(1, 0, 0, HEADER_HEIGHT - 2), Position = UDim2.fromOffset(0, 2), Parent = body }, { BackgroundColor3 = "Header" })
	window:_frame({ Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), Parent = header }, { BackgroundColor3 = "Border" })

	local titleRow = window:_frame({ Size = UDim2.new(1, window._mobile and -76 or -60, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Parent = header })
	List(titleRow, 6, Enum.FillDirection.Horizontal, { VerticalAlignment = Enum.VerticalAlignment.Center })
	local windowIcon = IconImage(Pick(p, nil, "icon"))
	if windowIcon then
		local icon = Create("ImageLabel", { Image = windowIcon, BackgroundTransparency = 1, Size = UDim2.fromOffset(16, 16), LayoutOrder = 1, Parent = titleRow })
		window:_paint(icon, { ImageColor3 = "Accent" })
	end
	local titleLabel = window:_label({ Size = UDim2.fromScale(0, 1), AutomaticSize = AUTO_X, TextSize = 14, LayoutOrder = 2, Parent = titleRow }, "Accent")
	window:_text(titleLabel, window.name)
	if window.subtitle then
		local subtitleLabel = window:_label({ Size = UDim2.fromScale(0, 1), AutomaticSize = AUTO_X, TextSize = 12, LayoutOrder = 3, Parent = titleRow }, "TextDim")
		window:_text(subtitleLabel, window.subtitle)
	end
	window._tagList = window:_frame({ Size = UDim2.fromScale(0, 1), AutomaticSize = AUTO_X, BackgroundTransparency = 1, LayoutOrder = 4, Parent = titleRow })
	List(window._tagList, 4, Enum.FillDirection.Horizontal, { VerticalAlignment = Enum.VerticalAlignment.Center })

	local buttonSize = window._mobile and 28 or 20
	local function headerButton(text, order)
		local button = Create("TextButton", {
			Text = text,
			TextSize = window._mobile and 16 or 14,
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(buttonSize, buttonSize),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -4 - (order - 1) * (buttonSize + 2), 0.5, 0),
			ZIndex = 5,
			Parent = header,
		})
		window:_paint(button, { TextColor3 = "TextDim", FontFace = "Font" })
		Hover(window, button, function()
			window:_paint(button, { TextColor3 = "Text" }, true)
		end, function()
			window:_paint(button, { TextColor3 = "TextDim" }, true)
		end)
		return button
	end
	local closeButton = headerButton("x", 1)
	window._minimiseButton = headerButton("-", 2)
	window:_connect(closeButton.Activated, function()
		window:Hide()
		local hint
		if window._mobile then
			hint = "Tap the " .. window._showName .. " button to open it again."
		else
			hint = "Press " .. KeyName(window.toggleKey) .. " to open it again."
		end
		window:Notify({ title = "Interface hidden", content = hint, duration = 4 })
	end)
	window:_connect(window._minimiseButton.Activated, function()
		window:ToggleMinimise()
	end)

	-- Navigation and pages
	local contentTop = HEADER_HEIGHT
	if window.sidebar then
		local rail = window:_frame({ Name = "Rail", Size = UDim2.new(0, RAIL_WIDTH, 1, -HEADER_HEIGHT), Position = UDim2.fromOffset(0, HEADER_HEIGHT), Parent = body }, { BackgroundColor3 = "Header" })
		window:_frame({ Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), Parent = rail }, { BackgroundColor3 = "Border" })
		local tabList = Create("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -1, 1, -48),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = AUTO_Y,
			ScrollBarThickness = 0,
			Parent = rail,
		})
		Padding(tabList, 6, 0, 6, 0)
		List(tabList, 2)
		window._tabList = tabList

		-- Profile
		local profile = window:_frame({ Size = UDim2.new(1, -1, 0, 48), Position = UDim2.new(0, 0, 1, -48), BackgroundTransparency = 1, Parent = rail })
		window:_frame({ Size = UDim2.new(1, -16, 0, 1), Position = UDim2.fromOffset(8, 0), Parent = profile }, { BackgroundColor3 = "Border" })
		local avatarOuter = window:_frame({ Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(10, 9), Parent = profile }, { BackgroundColor3 = "Outline" })
		local avatar = Create("ImageLabel", { Size = UDim2.new(1, -2, 1, -2), Position = UDim2.fromOffset(1, 1), BorderSizePixel = 0, Parent = avatarOuter })
		window:_paint(avatar, { BackgroundColor3 = "Element" })
		if LocalPlayer then
			task.spawn(function()
				local ok, url = pcall(function()
					return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
				end)
				if ok and avatar.Parent then
					avatar.Image = url
				end
			end)
		end
		local nameLabel = window:_label({
			Text = LocalPlayer and LocalPlayer.DisplayName or "Player",
			Size = UDim2.new(1, -52, 0, 14),
			Position = UDim2.fromOffset(46, 10),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = profile,
		}, "Text")
		nameLabel.TextSize = 12
		window._profileLabel = window:_label({ Size = UDim2.new(1, -52, 0, 12), Position = UDim2.fromOffset(46, 25), TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd, Parent = profile }, "TextDim")
		window:SetProfile(Pick(p, nil, "profile"))

		window._pages = window:_frame({ Name = "Pages", Size = UDim2.new(1, -RAIL_WIDTH, 1, -HEADER_HEIGHT), Position = UDim2.fromOffset(RAIL_WIDTH, HEADER_HEIGHT), BackgroundTransparency = 1, Parent = body })
	else
		local strip = window:_frame({ Name = "Tabs", Size = UDim2.new(1, 0, 0, TABSTRIP_HEIGHT), Position = UDim2.fromOffset(0, HEADER_HEIGHT), Parent = body }, { BackgroundColor3 = "Header" })
		window:_frame({ Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), Parent = strip }, { BackgroundColor3 = "Border" })
		window._tabList = window:_frame({ Size = UDim2.new(1, 0, 1, -1), BackgroundTransparency = 1, Parent = strip })
		List(window._tabList, 0, Enum.FillDirection.Horizontal)
		contentTop = HEADER_HEIGHT + TABSTRIP_HEIGHT
		window._pages = window:_frame({ Name = "Pages", Size = UDim2.new(1, 0, 1, -contentTop), Position = UDim2.fromOffset(0, contentTop), BackgroundTransparency = 1, Parent = body })
	end

	-- Resize grip
	local grip = Create("TextButton", {
		Name = "Resize",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(12, 12),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		ZIndex = 6,
		Parent = body,
	})
	for i = 0, 2 do
		for j = 0, i do
			window:_frame({ Size = UDim2.fromOffset(2, 2), Position = UDim2.fromOffset(9 - (i - j) * 3 - 1, 9 - j * 3 - 1 + 0), ZIndex = 6, Parent = grip }, { BackgroundColor3 = "Placeholder" })
		end
	end
	local resizeStart, resizeOrigin
	window:_draggable(nil, grip, function(position)
		if window.minimised then
			return
		end
		if not resizeStart then
			resizeStart, resizeOrigin = position, window._size
		end
		local delta = (position - resizeStart) * (1 / window._scale)
		local w = math.max(460, resizeOrigin.X + delta.X)
		local h = math.max(300, resizeOrigin.Y + delta.Y)
		window._size = Vector2.new(w, h)
		main.Size = UDim2.fromOffset(w, h)
		window:_closePopover()
	end, function()
		resizeStart = nil
	end)

	-- Window dragging
	local dragStart, dragOrigin
	window:_draggable(nil, header, function(position)
		if not dragStart then
			dragStart, dragOrigin = position, main.AbsolutePosition
			-- swap the centre anchor for top-left before moving
			main.AnchorPoint = Vector2.new(0, 0)
			main.Position = UDim2.fromOffset(dragOrigin.X, dragOrigin.Y)
			window:_closePopover()
		end
		local delta = position - dragStart
		local screen = gui.AbsoluteSize
		local x, y = dragOrigin.X + delta.X, dragOrigin.Y + delta.Y
		if screen.X > 0 then
			x = math.clamp(x, -main.AbsoluteSize.X + 60, screen.X - 60)
			y = math.clamp(y, 0, screen.Y - 30)
		end
		main.Position = UDim2.fromOffset(x, y)
	end, function()
		dragStart = nil
	end)

	-- Overlay layers
	window._overlay = window:_frame({ Name = "Overlay", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 10, Parent = gui })

	local notifyArea = window:_frame({ Name = "Notifications", Size = UDim2.new(0, 270, 1, -24), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -12), BackgroundTransparency = 1, ZIndex = 20, Parent = gui })
	List(notifyArea, 6, nil, { VerticalAlignment = Enum.VerticalAlignment.Bottom })
	window._notifyList = notifyArea

	window._toastTop = window:_frame({ Name = "ToastsTop", Size = UDim2.new(0, 340, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), BackgroundTransparency = 1, ZIndex = 20, Parent = gui })
	List(window._toastTop, 6, nil, { HorizontalAlignment = Enum.HorizontalAlignment.Center })
	window._toastBottom = window:_frame({ Name = "ToastsBottom", Size = UDim2.new(0, 340, 0.5, 0), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), BackgroundTransparency = 1, ZIndex = 20, Parent = gui })
	List(window._toastBottom, 6, nil, { HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Bottom })

	window._popupLayer = window:_frame({ Name = "Popups", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 30, Parent = gui })

	-- launcher: tap to toggle, drag to move
	local showIcon = IconImage(Pick(p, nil, "showicon"))
	local iconOnly = Pick(p, false, "showicononly") == true
	local topInset = GuiService:GetGuiInset().Y
	-- pc: top centre (only shows while hidden). mobile: left edge, clear of the window and the thumbstick
	local pill, pillFill = window:_rim({
		Name = "Launcher",
		Size = UDim2.fromOffset(0, 0),
		AnchorPoint = window._mobile and Vector2.new(0, 0.5) or Vector2.new(0.5, 0),
		Position = window._mobile and UDim2.new(0, 10, 0.35, 0) or UDim2.new(0.5, 0, 0, topInset + 8),
		ZIndex = 15,
		Visible = false,
		Parent = gui,
	}, "Panel")
	pill.AutomaticSize = AUTO_XY
	pillFill.Parent.AutomaticSize = AUTO_XY
	pillFill.Parent.Size = UDim2.new()
	pillFill.AutomaticSize = AUTO_XY
	pillFill.Size = UDim2.new()
	List(pillFill, 0)
	window._pillAccent = window:_frame({ Size = UDim2.new(1, 0, 0, 1), LayoutOrder = 1, Parent = pillFill }, { BackgroundColor3 = "Accent" })
	local pillRow = window:_frame({ Size = UDim2.new(), AutomaticSize = AUTO_XY, BackgroundTransparency = 1, LayoutOrder = 2, Parent = pillFill })
	if window._mobile then
		Padding(pillRow, 8, 14, 8, 14)
	else
		Padding(pillRow, 5, 10, 5, 10)
	end
	List(pillRow, 6, Enum.FillDirection.Horizontal, { VerticalAlignment = Enum.VerticalAlignment.Center })
	if showIcon then
		local icon = Create("ImageLabel", { Image = showIcon, BackgroundTransparency = 1, Size = UDim2.fromOffset(16, 16), Parent = pillRow })
		window:_paint(icon, { ImageColor3 = "Accent" })
	end
	if not (iconOnly and showIcon) then
		window._pillLabel = window:_label({ Size = UDim2.new(), AutomaticSize = AUTO_XY, TextSize = window._mobile and 14 or 12, LayoutOrder = 2, Parent = pillRow }, "Text")
	end
	window._pill = pill

	local pressStart, pressOrigin, pressMoved
	window:_draggable(nil, window:_hitbox(pill), function(position)
		if not pressStart then
			pressStart, pressOrigin, pressMoved = position, pill.AbsolutePosition, false
		end
		local delta = position - pressStart
		if not pressMoved and delta.Magnitude > 6 then
			pressMoved = true
			pill.AnchorPoint = Vector2.new(0, 0)
		end
		if pressMoved then
			local screen, size = gui.AbsoluteSize, pill.AbsoluteSize
			local x, y = pressOrigin.X + delta.X, pressOrigin.Y + delta.Y
			if screen.X > 0 then
				x = math.clamp(x, 0, math.max(0, screen.X - size.X))
				y = math.clamp(y, 0, math.max(0, screen.Y - size.Y))
			end
			pill.Position = UDim2.fromOffset(x, y)
		end
	end, function()
		local tapped = pressStart ~= nil and not pressMoved
		pressStart = nil
		if tapped then
			window:ToggleHide()
		end
	end)
	window:_refreshPill()

	-- Global input
	window:_connect(UserInputService.InputBegan, function(input)
		if IsPointerDown(input) and window._popover then
			local point = PointerPosition(input)
			if not Inside(window._popover.frame, point) and not Inside(window._popover.anchor, point) then
				window:_closePopover()
			end
		end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape and #window._popups > 0 then
				local top = window._popups[#window._popups]
				if top.dismissable then
					top:Close()
				end
				return
			end
			if UserInputService:GetFocusedTextBox() or window._listening then
				return
			end
			if KeyMatches(window.toggleKey, input) then
				window:ToggleHide()
			end
		elseif KeyMatches(window.toggleKey, input) and not window._listening and not UserInputService:GetFocusedTextBox() then
			window:ToggleHide()
		end
	end)
	local function belongsToDrag(drag, input, mouseType)
		if drag.input.UserInputType == Enum.UserInputType.Touch then
			return input == drag.input
		end
		return input.UserInputType == mouseType
	end
	window:_connect(UserInputService.InputChanged, function(input)
		local drag = window._drag
		if drag and belongsToDrag(drag, input, Enum.UserInputType.MouseMovement) then
			drag.move(PointerPosition(input))
		end
	end)
	window:_connect(UserInputService.InputEnded, function(input)
		local drag = window._drag
		if drag and belongsToDrag(drag, input, Enum.UserInputType.MouseButton1) then
			window._drag = nil
			if drag.page then
				drag.page.ScrollingEnabled = true
			end
			if drag.finish then
				drag.finish()
			end
		end
	end)

	-- window.Flags.X reads, window.Flags.X = v sets (and fires the callback)
	local function snapshot()
		local values = {}
		for flag in pairs(window._pending) do
			values[flag] = window:Get(flag)
		end
		for flag in pairs(window._elements) do
			values[flag] = window:Get(flag)
		end
		return values
	end
	window.Flags = setmetatable({}, {
		__index = function(_, flag)
			return window:Get(flag)
		end,
		__newindex = function(_, flag, value)
			if not window:Set(flag, value) then
				warn("[Onyx] unknown flag '" .. tostring(flag) .. "'")
			end
		end,
		__iter = function()
			return next, snapshot()
		end,
		__pairs = function()
			return next, snapshot(), nil
		end,
	})

	-- autoload: values get applied as each element is created
	if window._config and window._config.autoLoad and FileSystem.Available() then
		local _, path = window:GetPath()
		if isfile(path) then
			local ok, data = pcall(function()
				return HttpService:JSONDecode(readfile(path))
			end)
			if ok and type(data) == "table" and type(data.flags) == "table" then
				for flag, value in pairs(data.flags) do
					window._pending[flag] = value
				end
			end
		end
	end

	if Pick(p, true, "settingstab", "settings") ~= false then
		window:_buildSettings()
	end
	task.defer(function()
		if not window._activeTab and not window.unloaded then
			local first = window:_firstTab()
			if first then
				first:Select(true)
			end
		end
	end)

	MountGui(gui)
	-- refit on rotate/resize. deferred call is for screens that report size late
	window:_connect(gui:GetPropertyChangedSignal("AbsoluteSize"), function()
		window:_closePopover()
		window:_fitToScreen()
	end)
	window:_fitToScreen()
	task.defer(function()
		if not window.unloaded then
			window:_fitToScreen()
		end
	end)
	table.insert(Onyx.Windows, window)
	Onyx.Flags = window.Flags

	local status = Pick(p, nil, "status")
	if status ~= nil then
		window:SetStatus(status, Pick(p, nil, "statusnote"))
	end
	local statusUrl = Pick(p, nil, "statusurl")
	if statusUrl then
		window:_watchStatus(statusUrl, tonumber(Pick(p, nil, "statusrefresh")))
	end

	if keyOptions then
		window._keyLocked = true
		window.visible = false
		main.Visible = false
		window:_refreshPill()
		if not window:_runKeySystem(keyOptions) then
			-- prompt closed: tear down and park the calling script so nothing else runs
			window:Unload()
			coroutine.yield()
			return nil
		end
		window._keyLocked = false
		window:Show()
	end

	local changelog = Pick(p, nil, "changelog")
	local notice = Pick(p, nil, "notice")
	if changelog or notice then
		task.defer(function()
			if window.unloaded then
				return
			end
			if changelog then
				window:ShowChangelog(changelog)
			end
			if notice then
				window:ShowNotice(notice)
			end
		end)
	end
	return window
end

--------------------------------------------------------------------------------
-- Library level helpers
--------------------------------------------------------------------------------

local function LastWindow()
	return Onyx.Windows[#Onyx.Windows]
end

function Onyx:Notify(props)
	local window = LastWindow()
	if window then
		return window:Notify(props)
	end
	warn("[Onyx] Notify called before CreateWindow")
end

function Onyx:LoadConfiguration()
	local window = LastWindow()
	if not window then
		return false
	end
	window._loading = true
	local ok = window:Load()
	window._loading = false
	if window._config then
		window._config.autoLoad = true
	end
	return ok
end

function Onyx:SetVisibility(visible)
	for _, window in ipairs(Onyx.Windows) do
		if visible then
			window:Show()
		else
			window:Hide()
		end
	end
end

function Onyx:IsVisible()
	local window = LastWindow()
	return window ~= nil and window.visible
end

function Onyx:Destroy()
	for _, window in ipairs(CopyList(Onyx.Windows)) do
		window:Unload()
	end
end

Onyx.Themes = ThemeNames

-- so status = Onyx.Status.Patched autocompletes and can't be misspelled
Onyx.Status = { Working = "working", Updating = "updating", Patched = "patched" }

return Onyx
