# Mobile

You don't need to do anything, phones and tablets get detected (touch, no mouse) and the UI adjusts.

![mobile](images/mobile.png)

## What changes

- **launcher button**: a small square on the left side of the screen with your `showIcon` (or the first letter of the hub name). Tap it to open/close the menu, with the same pop animation as on PC. Drag it anywhere, and when you let go it slides to the nearest side so it's out of the way. It stays on screen the whole time since there's no keyboard to press RightShift on. On PC the launcher is a text pill that only shows while the menu is hidden.
- **scaling**: the window shrinks to fit the screen and refits when you rotate the phone. Dropdown lists and the colour picker scale with it, popups and the key prompt shrink if the screen is too narrow.
- **touch dragging**: sliders, the colour picker and the window follow the finger that started the drag. Your other thumb on the movement stick won't grab a slider by accident, and the page doesn't scroll while you're dragging a slider.
- **bigger targets**: header buttons, dropdown rows and slider hit areas are larger.
- the "hidden" message says to tap the button instead of naming a key.

## Options

```lua
Onyx:CreateWindow({
	name = "hub",
	mobile = true,      -- force mobile mode (or false to force pc mode)
	scale = 0.8,        -- fixed scale instead of auto fit
	showName = "menu",  -- launcher text (and the letter on the mobile square)
	launcherStyle = "text", -- mobile: the old text pill instead of the small square
	showIcon = 123,     -- launcher icon
	showIconOnly = true,
	showPill = false,   -- no launcher at all (careful, mobile players can't reopen it then)
})
```

## Mobile executors (Delta and co.)

Everything here is touch-first, so Delta, Fluxus, Codex, Arceus X and the like work the same as PC executors:

- the UI goes in `gethui()` when the executor has it, otherwise CoreGui, otherwise PlayerGui
- downloaded [images](images.md) use `getcustomasset` + `writefile`, which Delta has
- dragging uses the finger that started it, so moving with your left thumb while you drag a slider with your right works
- gallery tiles are bigger on phones (2 columns, taller tiles)
