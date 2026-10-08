# Notifications, popups, notice and changelog

## Notifications

Bottom right. Hovering pauses the timer, clicking closes it. At most 6 at once.

```lua
window:Notify({
	title = "Config loaded",
	content = "Restored your settings.",
	icon = 4483362458,
	duration = 4,          -- seconds, picked from the text length if you leave it out
})
```

## Toasts

Small pill at the top (or bottom). Good for quick "saved" type messages.

```lua
window:Toast({ title = "Saved" })
window:Toast({ title = "Nova", subtitle = "joined the server", avatar = 1 })   -- avatar = user id
window:Toast({ title = "Done", position = "Bottom", minWidth = 200, duration = 3 })
```

## Popups

A box in the middle of the screen with buttons.

```lua
window:Popup({
	title = "Reset everything?",
	content = "This clears every saved value.",
	options = {
		{ text = "Cancel" },
		{ text = "Reset", style = "danger", callback = function() reset() end },
	},
})
```

- button `style`: `"neutral"`, `"primary"` (accent colour) or `"danger"` (red)
- `boxes` shows little cards instead of (or under) the text: `{ title, description, icon, accent }`
- `dismissable = false` stops Escape and clicking outside from closing it
- it returns a handle with `:Close()`

## Notice on execute

Pops up over the menu right after the script runs.

```lua
Onyx:CreateWindow({
	name = "hub",
	notice = {
		title = "Heads up",
		content = "The game updated, some features might be broken for a bit.",
		button = "ok",
	},
})
```

You can also show one whenever: `window:ShowNotice("just a string works too")`.

## Changelog on execute

![changelog](images/changelog.png)

```lua
Onyx:CreateWindow({
	name = "hub",
	changelog = {
		once = true,   -- only show each version once per player
		entries = {
			{ version = "1.2.0", date = "2026-10-08", changes = { "Key system", "Fixed slider on mobile" } },
			{ version = "1.1.0", changes = { "Mobile support" } },
		},
	},
})
```

- put the newest version first, it gets highlighted
- `version` gets a `v` in front if it starts with a number
- `once = true` remembers the newest version in `Onyx/Seen/<name>.txt` and skips the popup until you add a newer one
- `title`, `subtitle`, `content` and `button` change the text around it
- `window:ShowChangelog({...})` shows it whenever you want

If you pass both `notice` and `changelog`, the notice shows on top.
