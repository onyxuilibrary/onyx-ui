# Colours

There are two ways to choose colours: pick the menu's own colour, or give your players colour pickers for your features (ESP colour, FOV circle and so on).

## Players pick the menu colour

The Settings tab has an **Accent colour** picker. Whatever colour players pick there becomes the menu's accent (toggles, sliders, the active tab, the title, links) and it changes live. It's saved with their config, so it comes back next time.

- Picking a theme in the Theme dropdown also moves the Accent colour picker to that theme's colour, so they always match.
- Don't want players changing it? `accentSetting = false` in `CreateWindow` removes the picker.

Set it from your script:

```lua
window:SetAccent(Color3.fromRGB(255, 120, 40))   -- also moves the picker in Settings
```

## Colour pickers for your features

Use `CreateColorPicker` anywhere you want the player to choose a colour, like ESP or chams:

```lua
local espColour = section:CreateColorPicker({
	name = "ESP colour",
	flag = "EspColour",                         -- saved with configs
	color = Color3.fromRGB(255, 70, 70),        -- starting colour, a Color3 or "#FF4646"
	alpha = 1,                                  -- optional see-through slider (0 to 1)
	callback = function(color, alpha)
		-- use the colour in your script
	end,
})
```

Clicking the swatch opens:

- a **saturation / brightness square**: drag to pick the shade
- a **hue bar**: drag to pick the colour
- an **alpha bar**: how see-through it is
- a **hex box**: type an exact colour like `FF4646` (with or without `#`) and press enter or tap away

It works with a finger on mobile too.

Reading and changing it from code:

```lua
print(espColour.value)                    -- the Color3
print(espColour.alpha)                    -- 0 to 1
espColour:Set(Color3.fromRGB(0, 200, 255))
espColour:SetAlpha(0.5)
print(window.Flags.EspColour)             -- same Color3, via its flag
```

The [ESP preview](esp-preview.md) can follow colour pickers by flag, so players see their colour on the dummy straight away.

## Your own theme colours

To ship your hub with your own colours instead, pass a theme table. Players can still change the accent in Settings.

```lua
Onyx:CreateWindow({
	name = "my hub",
	theme = {
		Accent = Color3.fromRGB(255, 120, 40),
		Background = Color3.fromRGB(12, 12, 14),
	},
})
```

Every colour you can set is listed in [themes](themes.md#keys).
