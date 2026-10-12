// Runs example.lua and examples/showcase.lua against the mock, in a thread like an executor
// would, and checks they finish without errors or warnings.
const fs = require("fs");
const path = require("path");
const { lua, lauxlib, lualib, to_luastring } = require("fengari");

const root = path.join(__dirname, "..");
const files = ["example.lua", "examples/showcase.lua"];
let failed = 0;

for (const file of files) {
	const L = lauxlib.luaL_newstate();
	lualib.luaL_openlibs(L);
	const set = (n, v) => { lua.lua_pushstring(L, to_luastring(v)); lua.lua_setglobal(L, to_luastring(n)); };
	set("__MOCK", fs.readFileSync(path.join(__dirname, "mock.lua"), "utf8"));
	set("__SRC", fs.readFileSync(path.join(root, "source.lua"), "utf8"));
	set("__EX", fs.readFileSync(path.join(root, file), "utf8"));
	set("__NAME", file);
	const driver = `
load(__MOCK, "@mock.lua")()
local M = __mock
loadstring = loadstring or load
-- the library comes from the loadstring, pictures get a fake png
game.HttpGet = function(_, url)
	if url:match("source%.lua$") then return __SRC end
	if url:match("%.png$") then return "\\137PNG" end
	error("404 " .. url)
end
local done, err = false, nil
task.spawn(function()
	local ok, e = xpcall(function() load(__EX, "@" .. __NAME)() end, debug.traceback)
	if not ok then err = e end
	done = true
end)
for _ = 1, 400 do
	if done then break end
	M.advance(0.05)
end
M.advance(1)
if err then error(err, 0) end
if not done then error("never finished", 0) end
if #M.errors > 0 then error(M.errors[1], 0) end
if #M.warnings > 0 then error("warnings: " .. table.concat(M.warnings, " | "), 0) end
return "ok"`;
	lauxlib.luaL_loadstring(L, to_luastring(driver));
	if (lua.lua_pcall(L, 0, 1, 0) !== lua.LUA_OK) {
		console.error(`example ${file}: FAILED\n${lua.lua_tojsstring(L, -1)}`);
		failed++;
	} else {
		console.log(`example ${file}: ok`);
	}
}
process.exit(failed ? 1 : 0);
