# Getting started

Load it:

```lua
local Onyx = loadstring(game:HttpGet("https://raw.githubusercontent.com/onyxuilibrary/onyx-ui/main/source.lua"))()
```

Make a window, a tab, a section, then put stuff in the section:

```lua
local window = Onyx:CreateWindow({ name = "my hub" })

local tab = window:CreateTab({ name = "Main" })
local section = tab:CreateSection("Player")

section:CreateToggle({
	name = "Infinite jump",
	callback = function(on)
		print(on)
	end,
})
```

That's the whole pattern. Everything else is options.

## A few things worth knowing

**Option names don't care about case.** `name`, `Name` and `NAME` all work, so you can write it however you like.

**Everything saves by default** once you turn on `configuration` in the window. Each value element (toggle, slider, etc.) is saved under its name. If you rename things a lot, give them a `flag` so old configs still load:

```lua
section:CreateSlider({ name = "Walk speed", flag = "WalkSpeed", range = { 16, 100 } })
```

Use `forgetState = true` on anything you don't want saved.

**Every value element has `.value` and `:Set()`.**

```lua
local speed = section:CreateSlider({ name = "Walk speed", range = { 16, 100 } })
print(speed.value)
speed:Set(50)        -- runs the callback
speed:Set(50, true)  -- doesn't
```

**Hide/show:** RightShift on PC (change it with `toggleKey` or in the settings tab). On mobile there's a button on the left side of the screen.

## Old style scripts

If you're coming from another library that uses PascalCase options, most of it just works:

```lua
local Window = Onyx:CreateWindow({
	Name = "hub",
	ConfigurationSaving = { Enabled = true, FolderName = "hub", FileName = "config" },
})
local Tab = Window:CreateTab("Main", 4483362458)
Tab:CreateSection("Stuff")
Tab:CreateToggle({ Name = "Toggle", CurrentValue = false, Flag = "Toggle1", Callback = function(v) end })
Tab:CreateSlider({ Name = "Slider", Range = { 0, 100 }, Increment = 1, CurrentValue = 10, Callback = function(v) end })
Tab:CreateDropdown({ Name = "Dropdown", Options = { "A", "B" }, CurrentOption = { "A" }, Callback = function(v) end })
Tab:CreateInput({ Name = "Input", PlaceholderText = "...", RemoveTextAfterFocusLost = true, Callback = function(t) end })
Tab:CreateKeybind({ Name = "Bind", CurrentKeybind = "Q", HoldToInteract = false, Callback = function() end })
Tab:CreateColorPicker({ Name = "Colour", Color = Color3.new(1, 1, 1), Callback = function(c) end })
Tab:CreateLabel("label")
Tab:CreateParagraph({ Title = "title", Content = "body" })
Onyx:Notify({ Title = "hi", Content = "there", Duration = 5 })
Onyx:LoadConfiguration()
```

`KeySystem = true` with a `KeySettings` table works too, see [key system](key-system.md).

Next: [window options](window.md).
