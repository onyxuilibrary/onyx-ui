# ESP preview

A panel that sits next to the menu with a dummy player on it, so people can see what their ESP settings will look like before they use them: box, name, health bar, distance, tracer and chams.

![esp preview](images/esp.png)

It only draws the picture. Your script still does the real ESP, the preview just shows the settings.

## Quick start

```lua
local preview = window:CreateESPPreview({
	bind = {
		box = "EspBoxes",         -- these are the flags of your own toggles / colour pickers
		name = "EspNames",
		health = "EspHealth",
		distance = "EspDistance",
		tracer = "EspTracers",
		chams = "EspChams",
		boxColor = "EspColour",
		tracerColor = "EspColour",
	},
})

-- a button that opens / closes it
section:CreateButton({ name = "ESP preview", callback = function() preview:Toggle() end })
```

With `bind`, the preview follows your toggles and colour pickers live. Turn on Tracers and the tracer shows up, change the ESP colour and the box changes colour too.

## Where it goes

It docks to the right of the menu and moves with it. If there's no room on the right it goes on the left, and if there's no room there either it sits inside the menu's right edge. It hides when the menu hides and scales with the menu on small screens.

## Options

Pass any of these to `CreateESPPreview`, or change them later with `preview:Set`:

| option | default | what it is |
|---|---|---|
| `box` | `true` | the box around the player |
| `name` | `true` | name above the box |
| `health` | `true` | health bar on the left |
| `distance` | `true` | distance under the box |
| `tracer` | `false` | line from the bottom |
| `chams` | `false` | tints the player |
| `boxColor` | white | box colour |
| `nameColor` | white | name and distance text |
| `tracerColor` | white | tracer colour |
| `chamsColor` | red | chams tint |
| `healthAmount` | `72` | how full the health bar is (0 to 100) |
| `playerName` | `Enemy` | the name shown |
| `distanceText` | `34m` | the distance shown |
| `title` | `ESP preview` | panel title |
| `open` | `false` | start open |
| `bind` | | `{ option = "Flag" }`, follow your own elements |

Names like `boxes`, `tracers`, `highlight`, `color` and `boxColour` work too.

## Methods

```lua
preview:Show()
preview:Hide()
preview:Toggle()
preview:IsOpen()
preview:Set("tracer", true)
preview:Set({ chams = true, chamsColor = Color3.fromRGB(0, 255, 120) })
preview:Get("box")
preview:Destroy()
```
