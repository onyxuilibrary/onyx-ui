# Script status

Lets people see at a glance if your script currently works.

![status](images/settings.png)

| status | colour |
|---|---|
| `working` | green |
| `updating` | orange |
| `patched` | red |

It shows up next to the window title and in the About box of the Settings tab (with your note underneath).

## Easiest way: one file you edit

You don't want to push a new script every time the game updates. So keep the status in a text file and point the window at it:

1. In your GitHub repo, make a file called `status.txt` and write `working` in it.
2. Open the file, click **Raw**, copy that link.
3. Use it as `statusUrl`:

```lua
local window = Onyx:CreateWindow({
	name = "my hub",
	statusUrl = "https://raw.githubusercontent.com/you/your-repo/main/status.txt",
})
```

Now when the game breaks your script, edit `status.txt` on GitHub to say `patched` and everyone sees red next time they run it. Change it back to `working` when it's fixed.

You can put a note in the file too, either after a colon or on the next lines:

```
updating: fixing aimbot after today's game update
```

```
patched
wait for the next update
join the discord for news
```

JSON works as well if you prefer: `{"status": "working", "note": "all good"}`

Want it to update for people who already have it open? Add `statusRefresh` (in seconds, minimum 10):

```lua
statusUrl = "https://raw.githubusercontent.com/you/your-repo/main/status.txt",
statusRefresh = 60,
```

Heads up: raw.githubusercontent.com caches files for a few minutes, so a change can take a moment to show up.

If the link can't be reached, the window just keeps whatever `status` you set locally, so it's worth setting both:

```lua
status = "working",
statusUrl = "https://raw.githubusercontent.com/you/your-repo/main/status.txt",
```

## Setting it in the script

```lua
local window = Onyx:CreateWindow({
	name = "my hub",
	status = Onyx.Status.Working,   -- or just "working"
	statusNote = "all features working",
})
```

`Onyx.Status.Working`, `Onyx.Status.Updating` and `Onyx.Status.Patched` are there so you can't typo it.

Change it any time:

```lua
window:SetStatus("updating", "fixing aimbot")
window:SetStatus(Onyx.Status.Patched)
window:SetStatus(nil)            -- hide it
print(window:GetStatus().state)  -- "patched"
```

## In your own settings tab

If you made your own settings tab (or turned the built-in one off), one line adds the status row:

```lua
local section = mySettings:CreateSection("Runtime")
section:CreateStatus()
```

It updates by itself whenever the status changes, including from `statusUrl`. Pass `state` to set the status at the same time: `section:CreateStatus({ state = "working", note = "all good" })`.

## Other options

- `statusTag = false` hides the pill next to the title (it still shows in settings)
- custom status: `window:SetStatus({ text = "Beta", color = Color3.fromRGB(0, 120, 255), note = "testers only" })`
- different label on a built-in one: `{ state = "patched", text = "Detected" }`
