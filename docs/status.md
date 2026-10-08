# Script status

Shows people whether your script works right now, so they don't spam your discord asking.

![status](images/settings.png)

There are three statuses:

| status | colour | use it when |
|---|---|---|
| `working` | green | everything works on the current game version |
| `updating` | orange | the game updated and you're fixing things, some features might be broken |
| `patched` | red | the script doesn't work right now, people shouldn't use it until you fix it |

It shows in two places:

- a little coloured tag next to the window title (`working` / `updating` / `patched`)
- the **About** box in the Settings tab, with your note underneath

The status is only a label. It doesn't turn anything off. If you want features to stop working when you're patched, check it yourself (see [checking the status in your code](#checking-the-status-in-your-code)).

---

## Pick one way to set it

There are two ways. **Use way 1 if you want to change the status without re-uploading your script**, which is almost always what you want.

### Way 1: a text file on GitHub (recommended)

You keep the status in a tiny text file. Everyone's script reads it when it starts, so you can flip it to `patched` from your phone and every user sees it next time they run your script.

**Step 1.** In your GitHub repo click **Add file → Create new file**. Name it `status.txt` and type just this one word:

```
working
```

Commit it.

**Step 2.** Open `status.txt` on GitHub and click the **Raw** button. Copy the link from your address bar. It should look like this:

```
https://raw.githubusercontent.com/YOUR-NAME/YOUR-REPO/main/status.txt
```

Use the link that starts with `raw.githubusercontent.com`. The normal `github.com/.../blob/...` link gives back a whole web page, not your text.

**Step 3.** Put that link in your window:

```lua
local window = Onyx:CreateWindow({
	name = "my hub",
	status = "working",   -- used if the file can't be reached
	statusUrl = "https://raw.githubusercontent.com/YOUR-NAME/YOUR-REPO/main/status.txt",
})
```

**Step 4.** When the game breaks your script, edit `status.txt` on GitHub, change the word to `patched` and commit. When you're working on it, use `updating`. When it's fixed, change it back to `working`.

#### What you can write in the file

| file contents | what people see |
|---|---|
| `working` | green, no note |
| `updating: fixing aimbot after today's update` | orange, note "fixing aimbot after today's update" |
| `patched` on the first line, more lines under it | red, the extra lines become the note |
| `{"status": "patched", "note": "wait for v2"}` | red, note "wait for v2" |

Example with a longer note:

```
patched
the game update broke everything
join the discord for news
```

Capital letters are fine (`Patched` works). Any other word shows as a grey tag and prints a warning in the console, so check your spelling.

#### Updating people who already have it open

By default the file is read once, when the script starts. To re-check it every so often, add `statusRefresh` (seconds, 10 minimum):

```lua
statusUrl = "https://raw.githubusercontent.com/YOUR-NAME/YOUR-REPO/main/status.txt",
statusRefresh = 60,   -- check once a minute
```

**Heads up:** GitHub caches raw files for about 5 minutes, so after you edit the file it can take a few minutes before people see the change. That's normal.

### Way 2: in the script itself

Good for testing, or if you don't use GitHub. To change it you have to update your script.

```lua
local window = Onyx:CreateWindow({
	name = "my hub",
	status = "working",
	statusNote = "all features work",   -- optional, shown under the status in settings
})
```

You can also write `Onyx.Status.Working`, `Onyx.Status.Updating` or `Onyx.Status.Patched` instead of the strings. Your editor will autocomplete those and you can't misspell them.

---

## Changing it while the script runs

```lua
window:SetStatus("updating", "fixing aimbot")   -- status + note
window:SetStatus("patched")                     -- just the status
window:SetStatus(nil)                           -- hide it completely
```

## Checking the status in your code

```lua
local status = window:GetStatus()   -- nil if no status is set
if status and status.state == "patched" then
	window:Notify({ title = "Patched", content = "This script is down right now, check the discord." })
	return
end
```

If you use `statusUrl`, the file is fetched in the background, so wait a second before checking, or check inside a button callback.

## Showing it in your own settings tab

The built-in Settings tab already shows the status. If you made your own settings tab (or turned the built-in one off with `settingsTab = false`), add it with one line:

```lua
local runtime = mySettingsTab:CreateSection("Runtime")
runtime:CreateStatus()
```

It updates by itself when the status changes, including from `statusUrl`. More options:

```lua
runtime:CreateStatus({ name = "Script" })                          -- different label on the left
runtime:CreateStatus({ state = "updating", note = "fixing esp" })  -- also sets the status
```

## Other options

- `statusTag = false` hides the tag next to the title. It still shows in settings.
- custom status: `window:SetStatus({ text = "Beta", color = Color3.fromRGB(0, 120, 255), note = "testers only" })`
- different word on a built-in colour: `window:SetStatus({ state = "patched", text = "Detected" })`

## Something not working?

| problem | fix |
|---|---|
| status never changes from the file | make sure the link starts with `raw.githubusercontent.com`, and open it in a private browser tab to check it's public |
| console says `couldn't fetch status` | the link is wrong, the repo is private, or the executor blocks `HttpGet` |
| console says `unknown status` | the file has a typo, it has to be `working`, `updating` or `patched` |
| changed the file but people still see the old status | wait about 5 minutes (GitHub cache), or use `statusRefresh` for people who already have it open |
